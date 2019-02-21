//
//  ProcessStack.swift
//  PatternAlert
//
//  Created by Piotr Domowicz on 23.01.19.
//  Copyright © 2019 patternAlert.de. All rights reserved.
//

import Cocoa

final class ProcessStack {
    
    var tasks: Set = Set<Task>()
    private var completion: (() -> Void)?
    
    // MARK: Public
    
    @discardableResult func onCompletion(completion: (() -> Void)?) -> Self {
        self.completion = completion
        return self
    }
    
    func addTask(task: Task) {
        tasks.insert(task)
        task.delegate = self
    }
    
    func cancelAll() {
        tasks.forEach{ task in
            task.isCanceled = true
        }
        tasks = Set<Task>()
    }
    
    // MARK: Private
    
    private func onCompletion() {
        completion?()
    }
}

extension ProcessStack: TaskDelegate {
    func didCompleteTask(task: Task) {
        tasks.remove(task)
        
        if tasks.isEmpty {
            onCompletion()
        }
    }
}

