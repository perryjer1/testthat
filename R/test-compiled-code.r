#' Test Compiled Code in a Package
#'
#' Test compiled code in the package \code{package}. See
#' \code{\link{use_catch}()} for more details.
#'
#' @param package The name of the package to test.
#'
#' @export
expect_cpp_tests_pass <- function(package) {

  routine <- get_routine(package, "run_testthat_tests")

  output <- ""
  tests_passed <- TRUE

  tryCatch(
    output <- utils::capture.output(tests_passed <- .Call(routine)),
    error = function(e) {
      warning(sprintf("failed to call test entrypoint '%s'", routine))
    }
  )

  # Drop first line of output (it's jut a '####' delimiter)
  info <- paste(output[-1], collapse = "\n")

  expect(tests_passed, paste("C++ unit tests:", info, sep = "\n"))

}

#' Use Catch for C++ Unit Testing
#'
#' Add the necessary infrastructure to enable C++ unit testing
#' in \R packages with
#' \href{https://github.com/philsquared/Catch}{Catch} and \code{testthat}.
#'
#' This function will:
#'
#' \enumerate{
#'   \item Create a file \code{src/test-runner.cpp}, which ensures that the
#'         \code{testthat} package will understand how to run your package's
#'         unit tests,
#'   \item Create an example test file \code{src/test-example.cpp}, which
#'         showcases how you might use \code{Catch} to write a unit test,
#'   \item Adds a test file \code{tests/testthat/test-cpp.R}, which ensures that
#'         \code{testthat} will run your compiled tests.
#' }
#'
#' C++ unit tests can be added to C++ source files within the
#' \code{src/} directory of your package, with a format similar
#' to \R code tested with \code{testthat} -- for example,
#'
#' \preformatted{
#' context("C++ Unit Test") {
#'   test_that("two plus two is four") {
#'     int result = 2 + 2;
#'     expect_true(result == 4);
#'   }
#' }
#' }
#'
#' When your package is compiled, unit tests alongside a harness
#' for running these tests will be compiled into the \R package,
#' with the entry point \code{run_testthat_tests()}. \code{testthat}
#' will use that entry point to run your unit tests when detected.
#'
#' @param dir The directory containing an \R package.
#'
#' @export
#' @seealso \href{https://github.com/philsquared/Catch}{Catch}, the
#'   library used to enable C++ unit testing.
use_catch <- function(dir = getwd()) {

  desc_path <- file.path(dir, "DESCRIPTION")
  if (!file.exists(desc_path))
    stop("no DESCRIPTION file at path '", desc_path, "'", call. = FALSE)

  desc <- read.dcf(desc_path, all = TRUE)
  pkg <- desc$Package
  if (!nzchar(pkg))
    stop("no 'Package' field in DESCRIPTION file '", desc_path, "'", call. = FALSE)

  src_dir <- file.path(dir, "src")
  if (!file.exists(src_dir) && !dir.create(src_dir))
    stop("failed to create 'src/' directory '", src_dir, "'", call. = FALSE)

  test_runner_path <- file.path(src_dir, "test-runner.cpp")

  # Copy the test runner.
  success <- file.copy(
    system.file(package = "testthat", "resources", "test-runner.cpp"),
    test_runner_path,
    overwrite = TRUE
  )

  if (!success)
    stop("failed to copy 'test-runner.cpp' to '", src_dir, "'", call. = FALSE)

  # Copy the test example.
  success <- file.copy(
    system.file(package = "testthat", "resources", "test-example.cpp"),
    file.path(src_dir, "test-example.cpp"),
    overwrite = TRUE
  )

  if (!success)
    stop("failed to copy 'test-example.cpp' to '", src_dir, "'", call. = FALSE)

  # Copy the 'test-cpp.R' file.
  test_dir <- file.path(dir, "tests", "testthat")
  if (!file.exists(test_dir) && !dir.create(test_dir, recursive = TRUE))
    stop("failed to create 'tests/testthat/' directory '", test_dir, "'", call. = FALSE)

  template_file <- system.file(package = "testthat", "resources", "test-cpp.R")
  contents <- readChar(template_file, file.info(template_file)$size, TRUE)
  transformed <- sprintf(contents, pkg)
  output_path <- file.path(test_dir, "test-cpp.R")
  cat(transformed, file = output_path)

  message("> Added C++ unit testing infrastructure.")
  message("> Please ensure you have 'LinkingTo: testthat' in your DESCRIPTION file.")

}

get_routine <- function(package, routine) {

  resolved <- tryCatch(
    getNativeSymbolInfo(routine, PACKAGE = package),
    error = function(e) NULL
  )

  if (is.null(resolved))
    stop("failed to locate routine '", routine, "' in package '", package, "'", call. = FALSE)

  resolved
}
