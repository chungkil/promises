// Copyright 2018 Google Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import PromisesTestHelpers
import XCTest
@testable import Promises

class PromiseAnyTests: XCTestCase {
  func testPromiseAny() {
    // Arrange.
    let promise1 = Promise<Any?> { fulfill, _ in
      Test.delay(0.1) {
        fulfill(42)
      }
    }
    let promise2 = Promise<Any?> { fulfill, _ in
      Test.delay(1) {
        fulfill("hello world")
      }
    }
    let promise3 = Promise<Any?> { fulfill, _ in
      Test.delay(2) {
        fulfill([42])
      }
    }
    let promise4 = Promise<Any?> { fulfill, _ in
      Test.delay(3) {
        fulfill(nil)
      }
    }

    // Act.
    let fastestPromise = any([promise1, promise2, promise3, promise4]).then { value in
      XCTAssertEqual(value as? Int, 42)
    }

    // Assert.
    XCTAssert(waitForPromises(timeout: 10))
    XCTAssertEqual(fastestPromise.value as? Int, 42)
    XCTAssertNil(fastestPromise.error)
  }

  func testPromiseAnyRejectFirst() {
    // Arrange.
    let promise1 = Promise { fulfill, _ in
      Test.delay(1) {
        fulfill(42)
      }
    }
    let promise2 = Promise<Int> { _, reject in
      Test.delay(0.1) {
        reject(Test.Error.code42)
      }
    }

    // Act.
    let fastestPromise = any([promise1, promise2]).then { _ in
      XCTFail()
    }.catch { error in
      XCTAssertTrue(error == Test.Error.code42)
    }

    // Assert.
    XCTAssert(waitForPromises(timeout: 10))
    XCTAssertTrue(fastestPromise.error == Test.Error.code42)
    XCTAssertNil(fastestPromise.value)
  }

  func testPromiseAnyRejectLast() {
    // Arrange.
    let promise1 = Promise { fulfill, _ in
      Test.delay(0.1) {
        fulfill(42)
      }
    }
    let promise2 = Promise<Int> { _, reject in
      Test.delay(1) {
        reject(Test.Error.code42)
      }
    }

    // Act.
    let fastestPromise = any([promise1, promise2]).then { value in
      XCTAssertEqual(value, 42)
    }

    // Assert.
    XCTAssert(waitForPromises(timeout: 10))
    XCTAssertEqual(fastestPromise.value, 42)
    XCTAssertNil(fastestPromise.error)
  }

  func testPromiseAnyNoDeallocUntilResolved() {
    // Arrange.
    let promise = Promise<Int>.pending()
    weak var weakExtendedPromise1: Promise<Int>?
    weak var weakExtendedPromise2: Promise<Int>?

    // Act.
    autoreleasepool {
      XCTAssertNil(weakExtendedPromise1)
      XCTAssertNil(weakExtendedPromise2)
      let extendedPromise1 = any([promise])
      let extendedPromise2 = any([promise])
      weakExtendedPromise1 = extendedPromise1
      weakExtendedPromise2 = extendedPromise2
      XCTAssertNotNil(weakExtendedPromise1)
      XCTAssertNotNil(weakExtendedPromise2)
    }

    // Assert.
    XCTAssertNotNil(weakExtendedPromise1)
    XCTAssertNotNil(weakExtendedPromise2)

    promise.fulfill(42)
    XCTAssert(waitForPromises(timeout: 10))

    XCTAssertNil(weakExtendedPromise1)
    XCTAssertNil(weakExtendedPromise2)
  }
}
