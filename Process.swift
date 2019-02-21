// Process.swift

/*
 
 MIT License
 
 Copyright (c) 2018 ReusableScrollView (https://github.com/sumofighter666/ReusableScrollView)
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 
 */

import Foundation

/**
 
 Use this class whenever you want to execute asynchronous operations with multiple attempts.
 Set the limit how many tries you want to run. Provide callback when operation has been successful and when all attempts failed
 
 ```
 Process.call(max:5, delay:2.0){ operation, count in
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        print("operation")
        operation.isSuccessful = false
    }
 }.onSuccess { _ in
    print("success")
 }.onFail { _ in
    print("fail")
 }
 
 ```
 
 */

protocol ProcessDelegate: class {
    func didCompleteProcess(Process: Process)
}

final class Process: Hashable {
    
    weak var delegate: ProcessDelegate?

	var success: ((Process) -> Void)?
	var failed: ((Process) -> Void)?
    var cancelled: ((Process) -> Void)?
	var operation: ((Process, UInt) -> Void)?

    var delay: TimeInterval = 1.0
    var isSuccessful = false
    var isCanceled = false
    
    private var maxLoop: UInt = 1
    private var hash = String.random(20)
    
    var hashValue: Int {
        return hash.hashValue
    }

	/**

	 `onSuccess` called when at least one attempt have been successful.

	 - Parameters:
		- completion: Optional failed closure that takes 1 argument - own object

	 - returns: Discardable `Process` object

	 */

	@discardableResult func onSuccess(completion: ((Process) -> Void)?) -> Self {
		self.success = completion
		return self
	}

	/**

	 `onFail` called when all attempts have been unsuccessful.

	 - Parameters:
		- completion: Optional failed closure that takes 1 argument - own object

	 - returns: Discardable `Process` object

	 */

	@discardableResult func onFail(completion: ((Process) -> Void)?) -> Self {
		self.failed = completion
		return self
	}
    
    /**
     
     `onCancel` called when attempts were requested to terminate loop.
     
     - Parameters:
     - completion: Optional failed closure that takes 1 argument - own object
     
     - returns: Discardable `Process` object
     
     */
    
    @discardableResult func onCancel(completion: ((Process) -> Void)?) -> Self {
        self.cancelled = completion
        return self
    }

	/**

	 `call` initializes loop run and call first attempt.
	 If no number of loops is provided then it is called only once, but if provided it calls every next loop with default time delay of 1 second

	 - returns: Discardable `Process` object

	 */

	@discardableResult func call() -> Self {
		self.call(attempt: 0)
		return self
	}

	/**

	 Static `call` function initializes loop run and call first attempt.

	 - Note: Once operation has been successful, set `isSuccessful` to true

	 - Parameters:
		- operation: Optional main operation closure that takes 2 arguments; own object and current count of call attempt
		- max: defines total number of calls should be run before failing
		- delay: defines delay between each call

	 - returns: Initialised `Process` object

	*/

	@discardableResult static func call(max: UInt = 1, delay: TimeInterval = 0, operation: ((Process, UInt) -> Void)?) -> Process {

		let loopOperation = Process()
		loopOperation.maxLoop = max
		loopOperation.operation = operation
		loopOperation.delay = delay

        let wait = delay == 0 ? 0.1 : delay
        
		DispatchQueue.main.asyncAfter(deadline: .now() + wait) {
            DispatchQueue.global(qos: .background).async {
                loopOperation.call(attempt: 0)
            }
		}

		return loopOperation
	}
    
    func cancel() {
        isCanceled = true
    }

	// MARK: Private

	private func call(attempt: UInt) {

        if isCanceled == true {
            self.cancelled?(self)
            self.delegate?.didCompleteProcess(Process: self)
            return
        }
        
		if attempt == maxLoop {
			self.failed?(self)
            self.delegate?.didCompleteProcess(Process: self)
			return
		}

		if isSuccessful == true {
            self.delegate?.didCompleteProcess(Process: self)
			guard let success = self.success else {
				return
			}
			success(self)
			return
		}

		guard let operation = self.operation else {
			return
		}

		operation(self, attempt)

		DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
			self.call(attempt: attempt + 1)
		}
	}
    
    static func ==(lhs: Process, rhs: Process) -> Bool {
        return lhs.hash == rhs.hash
    }
}
