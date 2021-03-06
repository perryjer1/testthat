/*
 * This is an example C++ file that leverages the
 * Catch unit testing library, alongside testthat's
 * simple bindings, to test a C++ function.
 *
 * For your own packages, ensure that your test files are
 * placed within the `tests/testthat/cpp` folder, and
 * that you include `LinkingTo: testthat` within your
 * DESCRIPTION file.
 */

// All test files should include the <tests/testthat.h>
// header file.
#include <testthat.h>

// Normally this would be a function from your package's
// compiled DLL -- you might instead just include a header
// file providing the definition, and let R CMD INSTALL
// handle building and linking.
int twoPlusTwo() { return 2 + 2; }

// Initialize a unit test context.
//
// Similar to the R level 'testthat::context()', except
// the enclosing context should be wrapped in braces.
context("Sample unit tests") {

  // The format for specifying tests is similar to that of
  // testthat's R functions, but a more limited set is
  // supported ('expect_true()', 'expect_false()').
  test_that("two plus two equals four") {
    expect_true(twoPlusTwo() == 4);
  }

}
