# 中文注释版 / Annotated source — VetBLCM 0.1.10
# XLSX 兼容性工具，不涉及诊断评价模型。
# 本次仅增加说明；统计行为与已验证的 0.1.10 相同。

# openxlsx 4.2.7.1 can leave unused drawing relationships pointing to parts that
# were never written. Strict Open XML readers reject these files. Remove only
# these unreferenced, absent drawing relationships from our own generated files.
# 修复 Excel 内部未使用的 drawing 关系，兼容严格读取器；不改写样本内容。
repair_unused_drawing_relationships <- function(path) {
  need_packages("zip")
  archive<-normalizePath(path,mustWork=TRUE)
  entries<-utils::unzip(archive,list=TRUE)$Name
  assert(!any(grepl("(^/|^[A-Za-z]:|(^|/)\\.\\.(/|$))",entries)),"Unsafe workbook archive paths")
  directory<-tempfile("vetblcm_xlsx_");dir.create(directory)
  on.exit({
    resolved<-normalizePath(directory,mustWork=FALSE,winslash="/")
    parent<-paste0(normalizePath(tempdir(),winslash="/"),"/")
    if(startsWith(resolved,parent)) unlink(directory,recursive=TRUE)
  },add=TRUE)
  utils::unzip(archive,exdir=directory)
  rels<-list.files(file.path(directory,"xl","worksheets","_rels"),pattern="\\.rels$",full.names=TRUE)
  changed<-FALSE
  for(file in rels) {
    text<-paste(readLines(file,warn=FALSE,encoding="UTF-8"),collapse="\n")
    matches<-regmatches(text,gregexpr("<Relationship\\b[^>]+/>",text,perl=TRUE))[[1]]
    sheet_file<-file.path(dirname(dirname(file)),sub("\\.rels$","",basename(file)))
    sheet<-paste(readLines(sheet_file,warn=FALSE,encoding="UTF-8"),collapse="\n")
    for(rel in matches) {
      target<-sub('.*Target="([^"]+)".*','\\1',rel)
      if(!grepl("^\\.\\./drawings/(drawing[0-9]+\\.xml|vmlDrawing[0-9]+\\.vml)$",target)) next
      target_file<-file.path(dirname(dirname(file)),target)
      if(file.exists(target_file)) next
      id<-sub('.*Id="([^"]+)".*','\\1',rel)
      assert(!grepl(paste0('r:id="',id,'"'),sheet,fixed=TRUE),"A worksheet references a missing drawing; refusing to alter it")
      text<-sub(rel,"",text,fixed=TRUE);changed<-TRUE
    }
    writeLines(text,file,useBytes=TRUE)
  }
  if(changed) {
    repaired<-tempfile(fileext=".xlsx");on.exit(unlink(repaired),add=TRUE)
    zip::zipr(repaired,files=list.files(directory,recursive=TRUE,all.files=TRUE,no..=TRUE),root=directory,mode="mirror",include_directories=FALSE)
    expected<-entries[!grepl("/$",entries)]
    assert(all(expected %in% utils::unzip(repaired,list=TRUE)$Name),"Workbook archive structure changed; refusing replacement")
    assert(file.copy(repaired,archive,overwrite=TRUE),"Cannot replace generated workbook")
  }
  invisible(path)
}

# 统一 Excel 显示所需的数据类型；标识符应保留字符串语义。
excel_display_data <- function(data) {
  data[]<-lapply(data,function(x) {if(is.character(x))x[x==""]<-NA_character_;x})
  data
}



# 将 Excel 字母列标转换为整数列号，用于推断实际工作表范围。
excel_column_number <- function(x) {
  vapply(strsplit(x, "", fixed = TRUE), function(chars) {
    sum((match(chars, LETTERS)) * 26 ^ rev(seq_along(chars) - 1L))
  }, numeric(1))
}

# 将整数列号转换为 Excel 字母列标，支持 Z 之后的多字母列。
excel_column_letters <- function(n) {
  vapply(as.integer(n), function(value) {
    assert(is.finite(value) && value >= 1L, "Invalid Excel column index")
    out <- character()
    while(value > 0L) {
      value <- value - 1L
      out <- c(LETTERS[(value %% 26L) + 1L], out)
      value <- value %/% 26L
    }
    paste0(out, collapse = "")
  }, character(1))
}

# 根据实际单元格位置确定工作表使用范围，而非信任可能过时的 dimension 属性。
worksheet_used_dimension <- function(text) {
  matches <- regmatches(text, gregexpr('<c\\b[^>]*\\br="[A-Z]+[0-9]+"', text, perl = TRUE))[[1]]
  if(!length(matches) || identical(matches, character(0)) || identical(matches, "")) return("A1")
  refs <- sub('.*\\br="([A-Z]+[0-9]+)".*', '\\1', matches, perl = TRUE)
  cols <- sub('[0-9]+$', '', refs)
  rows <- as.integer(sub('^[A-Z]+', '', refs))
  max_col <- max(excel_column_number(cols)); max_row <- max(rows)
  if(max_col == 1L && max_row == 1L) "A1" else paste0("A1:", excel_column_letters(max_col), max_row)
}

# 修正 XLSX 中工作表 dimension 元数据，使不同读取器识别到相同的数据范围。
repair_worksheet_dimensions <- function(path) {
  need_packages("zip")
  archive <- normalizePath(path, mustWork = TRUE)
  entries <- utils::unzip(archive, list = TRUE)$Name
  assert(!any(grepl("(^/|^[A-Za-z]:|(^|/)\\.\\.(/|$))", entries)), "Unsafe workbook archive paths")
  directory <- tempfile("vetblcm_xlsx_dimension_"); dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE, force = TRUE), add = TRUE)
  utils::unzip(archive, exdir = directory)
  sheets <- list.files(file.path(directory, "xl", "worksheets"), pattern = "^sheet[0-9]+\\.xml$", full.names = TRUE)
  changed <- FALSE
  for(file in sheets) {
    text <- paste(readLines(file, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
    wanted <- worksheet_used_dimension(text)
    tag <- regmatches(text, regexpr('<dimension\\s+ref="[^"]+"\\s*/>', text, perl = TRUE))
    if(length(tag) && nzchar(tag)) {
      current <- sub('.*ref="([^"]+)".*', '\\1', tag, perl = TRUE)
      if(!identical(current, wanted)) {
        text <- sub('<dimension\\s+ref="[^"]+"\\s*/>', paste0('<dimension ref="', wanted, '"/>'), text, perl = TRUE)
        changed <- TRUE
      }
    } else {
      text <- sub('(<worksheet\\b[^>]*>)', paste0('\\1<dimension ref="', wanted, '"/>'), text, perl = TRUE)
      changed <- TRUE
    }
    writeLines(text, file, useBytes = TRUE)
  }
  if(changed) {
    repaired <- tempfile(fileext = ".xlsx"); on.exit(unlink(repaired), add = TRUE)
    zip::zipr(repaired, files = list.files(directory, recursive = TRUE, all.files = TRUE, no.. = TRUE), root = directory, mode = "mirror", include_directories = FALSE)
    expected <- entries[!grepl("/$", entries)]
    assert(all(expected %in% utils::unzip(repaired, list = TRUE)$Name), "Workbook archive structure changed; refusing replacement")
    assert(file.copy(repaired, archive, overwrite = TRUE), "Cannot replace generated workbook")
  }
  invisible(path)
}

# 保存 openxlsx 工作簿后执行兼容性修复；最终文件仍为标准 XLSX。
save_vetblcm_workbook <- function(workbook,path) {
  openxlsx::saveWorkbook(workbook,path,overwrite=TRUE)
  repair_unused_drawing_relationships(path)
  repair_worksheet_dimensions(path)
}
