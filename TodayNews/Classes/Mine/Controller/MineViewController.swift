//
//  MineViewController.swift
//  TodayNews-Swift
//
//  Created by 杨蒙 on 2017/6/13.
//  Copyright © 2017年 杨蒙. All rights reserved.
//

import UIKit
import IBAnimatable

class MineViewController: UITableViewController {

    fileprivate var sections = [AnyObject]()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isNavigationBarHidden = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        /// 我的 我的界面 cell 数据
        NetworkTool.loadMineCellData { (sectionArray) in
            let dict = ["text": "我的关注", "grey_text": ""]
            let myConcern = MineCellModel(dict: dict as [String : AnyObject])
            var myConcerns = [MineCellModel]()
            myConcerns.append(myConcern)
            self.sections.append(myConcerns as AnyObject)
            self.sections += sectionArray
            self.tableView.reloadData()
        }
    }

    // 头部视图
    fileprivate lazy var noLoginHeaderView: NoLoginHeaderView = {
        let noLoginHeaderView = NoLoginHeaderView.headerView()
        noLoginHeaderView.delegate = self
        return noLoginHeaderView
    }()
}

// MARK: - NoLoginHeaderViewDelegate 未登录界面代理
extension MineViewController: NoLoginHeaderViewDelegate {
    /// 更多登录方式按钮点击
    func noLoginHeaderViewMoreLoginButotnClicked() {
        let storyboard = UIStoryboard(name: "MoreLoginViewController", bundle: nil)
        let moreLoginVC = storyboard.instantiateViewController(withIdentifier: "MoreLoginViewController") as! MoreLoginViewController
        moreLoginVC.modalSize = (width: .full, height: .custom(size: Float(screenHeight - 40)))
        present(moreLoginVC, animated: true, completion: nil)
    }
}

extension MineViewController {
    
    fileprivate func setupUI() {
        view.backgroundColor = UIColor.globalBackgroundColor()
        self.automaticallyAdjustsScrollViewInsets = false
        tableView.tableHeaderView = noLoginHeaderView
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: String(describing: UITableViewCell.self))
        tableView.register(UINib(nibName: String(describing: MineFirstSectionCell.self), bundle: nil), forCellReuseIdentifier: String(describing: MineFirstSectionCell.self))
        tableView.register(UINib(nibName: String(describing: MineOtherCell.self), bundle: nil), forCellReuseIdentifier: String(describing: MineOtherCell.self))
    }
    
}

// MARK: - // MARK: - Table view data source
extension MineViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 1 ? 1 : 10
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 10))
        view.backgroundColor = UIColor.globalBackgroundColor()
        return view
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 && indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: MineFirstSectionCell.self)) as! MineFirstSectionCell
            let mineCellModel = sections[0][0]  as! MineCellModel
            cell.mineCellModel = mineCellModel
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: MineOtherCell.self)) as! MineOtherCell
        let mineCellModel = sections[indexPath.section][indexPath.row]  as! MineCellModel
        cell.mineCellModel = mineCellModel
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
    
    // MARK: - UIScrollViewDelagate
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y;
        if offsetY < 0 {
            let totalOffset = kMineHeaderViewHieght + abs(offsetY)
            let f = totalOffset / kMineHeaderViewHieght
            noLoginHeaderView.bgImageView.frame = CGRect(x: -screenWidth * (f - 1) * 0.5, y: offsetY, width: screenWidth * f, height: totalOffset)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
