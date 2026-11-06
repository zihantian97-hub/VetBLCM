testthat::test_that("Strict-reader compatibility repair preserves worksheet contents", {
  w<-openxlsx::createWorkbook();openxlsx::addWorksheet(w,"Data");openxlsx::writeData(w,"Data",data.frame(ID=c("001","002"),Count=c(0,8)))
  file<-tempfile(fileext=".xlsx");openxlsx::saveWorkbook(w,file,overwrite=TRUE)
  sheet_bytes<-function(path) {con<-unz(path,"xl/worksheets/sheet1.xml",open="rb");on.exit(close(con));readBin(con,"raw",n=1e6)}
  before<-sheet_bytes(file)
  repair_unused_drawing_relationships(file)
  after<-sheet_bytes(file)
  testthat::expect_identical(before,after)
  got<-readxl::read_excel(file);testthat::expect_equal(got$ID,c("001","002"));testthat::expect_equal(got$Count,c(0,8))
  unlink(file)
})

testthat::test_that("Generated workbooks advertise their actual worksheet dimensions", {
  w<-openxlsx::createWorkbook();openxlsx::addWorksheet(w,"Data");openxlsx::writeData(w,"Data",data.frame(ID=c("001","002"),Count=c(0,8)))
  file<-tempfile(fileext=".xlsx");save_vetblcm_workbook(w,file)
  con<-unz(file,"xl/worksheets/sheet1.xml",open="rb")
  text<-rawToChar(readBin(con,"raw",n=1e6));close(con)
  dimension<-regmatches(text,regexpr('<dimension\\s+ref="[^"]+"\\s*/>',text,perl=TRUE))
  testthat::expect_match(dimension,'ref="A1:B3"',fixed=TRUE)
  got<-readxl::read_excel(file);testthat::expect_equal(nrow(got),2);testthat::expect_equal(ncol(got),2)
  unlink(file)
})
