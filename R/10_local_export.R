# 中文注释版 / Annotated source — VetBLCM 0.1.10
# 本地目录选择、完整导出、ZIP 和文件完整性校验。
# 本次仅增加说明；统计行为与已验证的 0.1.10 相同。

# 清理文件夹名称中的非法字符和 Windows 保留名，避免研究名称成为无效路径。
sanitize_path_component <- function(x, fallback = "VetBLCM_Project", max_chars = 80L) {
  x <- trimws(as.character(x %||% ""))
  x <- gsub("[[:cntrl:]<>:\"/\\\\|?*]", "_", x, perl = TRUE)
  x <- gsub("[. ]+$", "", x, perl = TRUE)
  x <- gsub("_+", "_", x, perl = TRUE)
  if(!nzchar(x)) x <- fallback
  reserved <- c("CON","PRN","AUX","NUL",paste0("COM",1:9),paste0("LPT",1:9))
  if(toupper(x) %in% reserved) x <- paste0("_", x)
  substr(x, 1L, max_chars)
}

# 优先使用 VETBLCM_OUTPUT_DIR 环境变量，否则选择用户文档目录下的 VetBLCM。
default_local_output_root <- function() {
  configured <- trimws(Sys.getenv("VETBLCM_OUTPUT_DIR", unset = ""))
  if(nzchar(configured)) return(path.expand(configured))
  home <- path.expand("~")
  documents <- file.path(home, "Documents")
  if(dir.exists(documents)) file.path(documents, "VetBLCM") else file.path(home, "VetBLCM")
}

# 建立输出目录并检查写入能力；返回规范化绝对路径。
prepare_local_output_root <- function(path) {
  path <- trimws(as.character(path %||% ""))
  assert(nzchar(path), "Choose a local output directory / 请选择本地结果目录")
  path <- path.expand(path)
  if(!dir.exists(path)) assert(dir.create(path, recursive = TRUE, showWarnings = FALSE), paste("Cannot create output directory / 无法创建结果目录:", path))
  root <- normalizePath(path, winslash = "/", mustWork = TRUE)
  probe <- tempfile(pattern = ".vetblcm-write-test-", tmpdir = root)
  ok <- file.create(probe)
  if(ok) unlink(probe)
  assert(isTRUE(ok), paste("Output directory is not writable / 结果目录不可写:", root))
  root
}

# 按运行时间、分析物及分析标识建立目录，区分不同运行。
unique_local_run_directory <- function(root, fit) {
  started <- suppressWarnings(as.POSIXct(fit$started %||% NA_character_))
  if(length(started)!=1L || is.na(started)) started <- Sys.time()
  date_dir <- file.path(root, format(started, "%Y-%m-%d"))
  if(!dir.exists(date_dir)) assert(dir.create(date_dir, recursive = TRUE, showWarnings = FALSE), "Cannot create date directory / 无法创建日期目录")
  analyte <- sanitize_path_component(fit$metadata$pathogen %||% "analyte", "analyte", 32L)
  token <- gsub("[^A-Za-z0-9]", "", as.character(fit$id %||% "analysis"))
  if(nchar(token)>10L) token <- substr(token, nchar(token)-9L, nchar(token))
  if(!nzchar(token)) token <- "analysis"
  file.path(date_dir, paste0("run_", format(started, "%H%M%S"), "_", analyte, "_", token))
}

# 计算文件字节哈希，供导出完整性检查；不同于对 R 对象序列化后的哈希。
sha256_file <- function(path) {
  need_packages("digest")
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}

# 记录相对路径、字节数及 SHA256；避免在分享清单中泄露本地绝对保存位置。
write_local_export_manifest <- function(directory, fit) {
  need_packages(c("jsonlite","digest"))
  files <- list.files(directory, recursive = TRUE, all.files = TRUE, no.. = TRUE, full.names = TRUE, include.dirs = FALSE)
  files <- files[basename(files) != "local_export_manifest.json"]
  relative <- substring(normalizePath(files, winslash = "/", mustWork = TRUE), nchar(normalizePath(directory, winslash = "/", mustWork = TRUE)) + 2L)
  records <- lapply(seq_along(files), function(i) list(path = relative[[i]], bytes = unname(file.info(files[[i]])$size), sha256 = sha256_file(files[[i]])))
  manifest <- list(
    application = "VetBLCM",
    schema_version = 1L,
    analysis_id = fit$id,
    exported_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
    note = "Paths are relative so the analysis bundle can be shared without exposing the local save location.",
    files = records
  )
  jsonlite::write_json(manifest, file.path(directory, "local_export_manifest.json"), pretty = TRUE, auto_unbox = TRUE, digits = NA)
  invisible(manifest)
}

# 先在临时目录完整导出并打包，再替换同一次运行的目标目录；失败时保留原有结果或清理临时输出。
save_analysis_local <- function(fit, output_root = default_local_output_root(), comparison = NULL, sensitivity = NULL,
                                review = list(), language = "zh", all_figures = TRUE) {
  assert(!is.null(fit), "Run or restore an analysis with posterior draws before saving / 保存前请先运行或恢复包含后验抽样的分析")
  need_packages(c("zip","digest","jsonlite","openxlsx"))
  root <- prepare_local_output_root(output_root)
  final_dir <- unique_local_run_directory(root, fit)
  project_dir <- dirname(final_dir)
  staging <- tempfile(pattern = ".vetblcm-export-", tmpdir = project_dir)
  assert(dir.create(staging, recursive = TRUE, showWarnings = FALSE), "Cannot create temporary export directory / 无法创建临时导出目录")
  committed <- FALSE
  on.exit(if(!committed && dir.exists(staging)) unlink(staging, recursive = TRUE, force = TRUE), add = TRUE)

  export_analysis(fit, staging, comparison, sensitivity, review, language, all_figures = all_figures)
  write_local_export_manifest(staging, fit)

  bundle_tmp <- tempfile(pattern = "VetBLCM-bundle-", tmpdir = project_dir, fileext = ".zip")
  on.exit(if(file.exists(bundle_tmp)) unlink(bundle_tmp), add = TRUE)
  relative_files <- list.files(staging, recursive = TRUE, all.files = TRUE, no.. = TRUE, include.dirs = FALSE)
  zip::zipr(bundle_tmp, files = relative_files, root = staging, mode = "mirror", include_directories = FALSE)
  bundle_name <- paste0("VetBLCM_", sanitize_path_component(fit$id, "analysis", 64L), ".zip")
  assert(file.copy(bundle_tmp, file.path(staging, bundle_name), overwrite = TRUE), "Could not place complete analysis ZIP / 无法写入完整分析ZIP")

  backup <- NULL
  if(dir.exists(final_dir)) {
    backup <- tempfile(pattern = paste0(".", basename(final_dir), "-backup-"), tmpdir = dirname(final_dir))
    assert(file.rename(final_dir, backup), "Could not stage previous copy of this run / 无法暂存该运行的旧保存副本")
  }
  finalized <- file.rename(staging, final_dir)
  if(!isTRUE(finalized)) {
    if(!is.null(backup) && dir.exists(backup)) file.rename(backup, final_dir)
    stop("Could not finalize local analysis directory / 无法完成本地结果目录写入", call. = FALSE)
  }
  committed <- TRUE
  if(!is.null(backup) && dir.exists(backup)) unlink(backup, recursive = TRUE, force = TRUE)
  bundle_path <- file.path(final_dir, bundle_name)
  list(directory = normalizePath(final_dir, winslash = "/", mustWork = TRUE),
       bundle = normalizePath(bundle_path, winslash = "/", mustWork = TRUE),
       bundle_sha256 = sha256_file(bundle_path))
}

# 在 Windows 中打开本地目录选择器；与统计计算无关，取消选择返回空结果。
select_local_output_directory <- function(initial = default_local_output_root()) {
  initial <- path.expand(initial %||% default_local_output_root())
  if(.Platform$OS.type != "windows") return(NULL)
  start <- initial
  while(!dir.exists(start) && !identical(dirname(start), start)) start <- dirname(start)
  start <- normalizePath(start, winslash = "\\", mustWork = TRUE)

  # Rscript/Shiny desktop sessions do not reliably show utils::choose.dir().
  # Prefer a native .NET FolderBrowserDialog launched in STA PowerShell and
  # use an invisible top-most owner form so the dialog is brought to the front.
  ps_candidates <- c(Sys.which("powershell.exe"), Sys.which("pwsh.exe"))
  ps <- ps_candidates[nzchar(ps_candidates)][1]
  if(length(ps) && !is.na(ps) && nzchar(ps)) {
    script <- tempfile(pattern = "vetblcm-folder-", fileext = ".ps1")
    on.exit(unlink(script), add = TRUE)
    code <- c(
      "param([string]$InitialPath)",
      "Add-Type -AssemblyName System.Windows.Forms",
      "$owner = New-Object System.Windows.Forms.Form",
      "$owner.ShowInTaskbar = $false",
      "$owner.TopMost = $true",
      "$owner.StartPosition = 'CenterScreen'",
      "$owner.Size = New-Object System.Drawing.Size(1,1)",
      "$owner.Opacity = 0",
      "$owner.Show()",
      "$dialog = New-Object System.Windows.Forms.FolderBrowserDialog",
      "$dialog.Description = 'VetBLCM results directory / VetBLCM results folder'",
      "$dialog.ShowNewFolderButton = $true",
      "if (Test-Path -LiteralPath $InitialPath -PathType Container) { $dialog.SelectedPath = $InitialPath }",
      "$result = $dialog.ShowDialog($owner)",
      "$owner.Close()",
      "$owner.Dispose()",
      "if ($result -eq [System.Windows.Forms.DialogResult]::OK) { [Console]::Out.WriteLine($dialog.SelectedPath) } else { [Console]::Out.WriteLine('__VETBLCM_CANCEL__') }",
      "$dialog.Dispose()"
    )
    writeLines(code, script, useBytes = TRUE)
    out <- tryCatch(system2(ps, c("-NoProfile","-STA","-ExecutionPolicy","Bypass","-File",shQuote(script),shQuote(start)), stdout = TRUE, stderr = TRUE), error = function(e)e)
    if(!inherits(out, "error")) {
      status <- attr(out, "status") %||% 0L
      clean <- trimws(as.character(out))
      clean <- clean[nzchar(clean)]
      if(identical(as.integer(status), 0L) && length(clean)) {
        if(any(clean == "__VETBLCM_CANCEL__")) return(NULL)
        candidate <- tail(clean[clean != "__VETBLCM_CANCEL__"], 1L)
        if(length(candidate) && dir.exists(candidate)) return(normalizePath(candidate, winslash = "/", mustWork = TRUE))
      }
    }
  }

  # Fallback for unusual Windows/R installations. The path can always be typed
  # directly on Page 1 if both native dialogs are unavailable.
  chosen <- tryCatch(utils::choose.dir(default = start, caption = "VetBLCM results directory / VetBLCM结果目录"), error = function(e) NA_character_)
  if(is.na(chosen) || !nzchar(chosen)) NULL else normalizePath(chosen, winslash = "/", mustWork = TRUE)
}

# 用系统文件管理器打开已经存在的输出目录。
open_local_directory <- function(path) {
  path <- normalizePath(path, winslash = "/", mustWork = TRUE)
  if(.Platform$OS.type == "windows") {
    shell.exec(path)
    return(TRUE)
  }
  FALSE
}
