//
//  DBConnection.swift
//  MHDatabase
//
//  Created by minhao on 17/7/7.
//  Copyright © 2017年 MH. All rights reserved.
//

import UIKit

/**
 * @brief 数据库连接
 *
 *
 */
public final class DBConnection {

    //定义数据库的存储方式
    public enum Location : CustomStringConvertible {
        case inMemory       //内存数据库
        case temporary      //临时数据库
        case uri(String)    //指定地址
    
        //处理文件名称 具体内容
        public var description: String {
            switch self {
            case .inMemory:
                return ":menory:"
            case .temporary:
                return ""
            case .uri(let path):
                return path

            }
        }
    }
    
    //定义数据库操作类型(添加、更新、删除、查询)
    public enum Operation {
        case insert
        case update
        case delete
        case select
        
        //数据库类型->枚举类型
        fileprivate init(value:Int32) {
            switch value {
            case SQLITE_INSERT:
                self = .insert
            case SQLITE_UPDATE:
                self = .update
            case SQLITE_DELETE:
                self = .delete
            case SQLITE_SELECT:
                self = .select
            default:
                fatalError("Nonexistent this operation type!")
            }
        }
    }
    
    //构建数据库连接
    fileprivate var handle : OpaquePointer? = nil
    fileprivate var queue = DispatchQueue(label:"sqlite");
    fileprivate static let queueKey = DispatchSpecificKey<Int>()
    fileprivate lazy var queueContext : Int = unsafeBitCast(self, to: Int.self);
    init(_ location:Location = .inMemory, readonly:Bool=false) throws{
        //打开数据库
        let flags = readonly ? SQLITE_OPEN_READONLY : SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE;
        
        try check(sqlite3_open_v2(location.description, &handle, flags | SQLITE_OPEN_FULLMUTEX, nil));
        
        //给数据库设置标记（队列) 避免操作数据库并发
        queue.setSpecific(key: DBConnection.queueKey, value: queueContext)
    }
    
    convenience init(_ fileName:String, readonly:Bool = false) throws{
        try self.init(.uri(fileName), readonly:readonly);
    }
    
    //处理数据库异常信息
    @discardableResult
    func check(_ resultCode: Int32) throws -> Int32 {
        guard let error = DBResult(errorCode:resultCode, connection:self)  else {
            return resultCode
        }
        
        throw error
        
    }
    
    //监测数据库操作
    public var readonly : Bool {
        return sqlite3_db_readonly(handle, nil) == 1
    }
    
    
    
    public var changes : Int {
        return Int(sqlite3_changes(handle))
    }
    
    public var totalChanges : Int {
        return Int(sqlite3_total_changes(handle))
    }
    
    //执行SQL语句
    public func execute(_ sql:String) throws {
        _ = try dbSync{
            try self.check(sqlite3_exec(self.handle, sql, nil, nil, nil))
        }
    }
    
    //保证同步->传递闭包
    public func dbSync<T>( _ callback:@escaping () throws -> T) rethrows -> T{
        var success:T?
        var failure:Error?
        
        //临时代码块 处理异常结果
        let box : () -> Void = {
            do {
                success = try callback()
            } catch  {
                failure = error
            }
        }
        
        
        if DispatchQueue.getSpecific(key:DBConnection.queueKey) == queueContext {
            box()     //当前队列
        }else {
            queue.sync(execute: box) //其他子队列
        }
        
    
        if let fail = failure {
            try { () -> Void in
                throw fail
            }()
        }
        
        return success!
    }
    
}

//异常信息（数据库返回结果）
public enum DBResult : Error {
    fileprivate static let successCodes = [SQLITE_OK, SQLITE_ROW, SQLITE_DONE];
    case error(message:String, code:Int32)
    
    init?(errorCode: Int32, connection:DBConnection) {
        guard !DBResult.successCodes.contains(errorCode) else {
            return nil
        }
        
        let message = String(cString: sqlite3_errmsg(connection.handle))
        self = .error(message: message, code: errorCode)
    }
}
