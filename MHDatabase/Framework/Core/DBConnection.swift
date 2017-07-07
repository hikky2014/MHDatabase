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
public final class DBConnection: NSObject {

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
    fileprivate var queueContext : Int = unsafeBitCast(self, to: Int.self);
    init(_ location:Location = .inMemory, readonly:Bool=false) throws{
        //打开数据库
        // SQLITE_OPEN_FULLMUTEX 数据库连接串行模式
        let flags = readonly ? SQLITE_OPEN_READONLY : SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE;
        sqlite3_open_v2(location.description, &handle, flags | SQLITE_OPEN_FULLMUTEX, nil);
        
        //给数据库设置标记（队列) 避免操作数据库是并发
        queue.setSpecific(key: DBConnection.queueKey, value: queueContext)
    }
    
    convenience init(_ fileName:String, readonly:Bool = false) throws{
        try self.init(.uri(fileName), readonly:readonly);
    }
    
}
