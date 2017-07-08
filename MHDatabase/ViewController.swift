//
//  ViewController.swift
//  MHDatabase
//
//  Created by minhao on 17/7/7.
//  Copyright © 2017年 MH. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //执行SQL
        let path = Bundle.main.path(forResource: "test", ofType: ".db")
        print(path!)
        
        do {
            let connection = try DBConnection(path!)
            print(connection.readonly);
            try connection.execute("create table t_teacher(t_uname text, t_sex text)")
        } catch  {
            print("出现异常：\(error)")
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

