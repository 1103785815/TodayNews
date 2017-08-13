//
//  NetworkTool.swift
//  TodayNews-Swift
//
//  Created by 杨蒙 on 17/2/16.
//  Copyright © 2017年 杨蒙. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import SVProgressHUD

class NetworkTool {
    
    /// -------------------------- 首 页 home -------------------------
    // MARK: - 获取首页顶部标题内容
    /// 获取首页顶部标题内容
    class func loadHomeTitlesData(fromViewController: String, completionHandler:@escaping (_ topTitles: [TopicTitle], _ homeTopicVCs: [TopicViewController])->()) {
        let url = BASE_URL + "article/category/get_subscribed/v1/?"
        let params = ["device_id": device_id,
                      "aid": 13,
                      "iid": IID] as [String : Any]
        Alamofire.request(url, parameters: params).responseJSON { (response) in
            guard response.result.isSuccess else {
                return
            }
            if let value = response.result.value {
                let json = JSON(value)
                let dataDict = json["data"].dictionary
                if let data = dataDict!["data"]!.arrayObject {
                    var titles = [TopicTitle]()
                    var homeTopicVCs = [TopicViewController]()
                    
                    // 添加推荐标题
                    let recommendDict = ["category": "", "name": "推荐"]
                    let recommend = TopicTitle(dict: recommendDict as [String : AnyObject])
                    titles.append(recommend)
                    // 添加控制器
                    let firstVC = TopicViewController()
                    firstVC.topicTitle = recommend
                    homeTopicVCs.append(firstVC)
                    for dict in data {
                        let topicTitle = TopicTitle(dict: dict as! [String: AnyObject])
                        titles.append(topicTitle)
                        let homeTopicVC = TopicViewController()
                        homeTopicVC.topicTitle = topicTitle
                        homeTopicVCs.append(homeTopicVC)
                    }
                    completionHandler(titles, homeTopicVCs)
                }
            }
        }
    }
    
    /// 点击首页加号按钮，获取频道推荐数据
    class func loadHomeCategoryRecommend(completionHandler:@escaping (_ topTitles: [TopicTitle]) -> ()) {
        SVProgressHUD.show(withStatus: "正在加载...")
        SVProgressHUD.setBackgroundColor(UIColor(r: 0, g: 0, b: 0, alpha: 0.5))
        SVProgressHUD.setForegroundColor(UIColor.white)
        let url = BASE_URL + "article/category/get_extra/v1/?"
        let params = ["device_id": device_id]
        Alamofire.request(url, parameters: params).responseJSON { (response) in
            SVProgressHUD.dismiss()
            guard response.result.isSuccess else {
                return
            }
            if let value = response.result.value {
                let json = JSON(value)
                let dataDict = json["data"].dictionary
                if let data = dataDict!["data"]!.arrayObject {
                    var titles = [TopicTitle]()
                    for dict in data {
                        let topicTitle = TopicTitle(dict: dict as! [String: AnyObject])
                        titles.append(topicTitle)
                    }
                    completionHandler(titles)
                }
            }
        }
    }
    
    /// 搜索
    class func loadSearchResult(keyword: String, offset: Int, completionHandler:@escaping (_ weitoutiao: [WeiTouTiao]) -> ()) {
        let url = BASE_URL + "api/2/wap/search_content/?"
        let params = ["device_id": device_id,
                      "keyword": keyword,
                      "from": "search_tab",
                      "count": "10",
                      "cur_tab": "1",
                      "format": "json",
                      "offset": offset,
                      "search_text": keyword] as [String: AnyObject]
        Alamofire.request(url, parameters: params).responseJSON { (response) in
            guard response.result.isSuccess else {
                return
            }
            if let value = response.result.value {
                let json = JSON(value)
                if let data = json["data"].arrayObject {
                    var weitoutiaos = [WeiTouTiao]()
                    for dict in data {
                        let weitoutiao = WeiTouTiao(dict: dict as! [String: AnyObject])
                        weitoutiaos.append(weitoutiao)
                    }
                    completionHandler(weitoutiaos)
                }
            }
        }
    }
    
    /// 获取首页不同分类的新闻内容(和视频内容使用一个接口)
    class func loadHomeCategoryNewsFeed(category: String, completionHandler:@escaping (_ nowTime: TimeInterval,_ newsTopics: [WeiTouTiao])->()) {
        var url = String()
        var params = [String: String]()
        if category == "image_ppmm" { //  如果是美女分类
            url =  "https://is.snssdk.com/api/news/feed/v58/?"
            params = ["device_id": "24694334167",
                          "category": category,
                          "iid": "13142832815",
                          "device_platform": "iphone"]
        } else {
            url = BASE_URL + "api/news/feed/v39/?"
            params = ["device_id": device_id,
                          "category": category,
                          "iid": IID,
                          "device_platform": "iphone"]
        }
        let nowTime = NSDate().timeIntervalSince1970
        Alamofire.request(url, parameters: params).responseJSON { (response) in
            guard response.result.isSuccess else {
                return
            }
            if let value = response.result.value {
                let json = JSON(value)
                guard let dataJSONs = json["data"].array else {
                    return
                }
                var topics = [WeiTouTiao]()
                for data in dataJSONs {
                    if let content = data["content"].string {
                        let contentData: NSData = content.data(using: String.Encoding.utf8)! as NSData
                        do {
                            let dict = try JSONSerialization.jsonObject(with: contentData as Data, options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary
                            let topic = WeiTouTiao(dict: dict as! [String : AnyObject])
                            topics.append(topic)
                        } catch {
                            
                        }
                    }
                }
                completionHandler(nowTime, topics)
            }
        }
    }
    
    /// 获取图片新闻详情数据
    class func loadNewsDetail(articleURL: String, completionHandler:@escaping (_ images: [NewsDetailImage], _ abstracts: [String])->()) {
        // 测试数据
//        http://toutiao.com/item/6450211121520443918/
        let url = "http://www.toutiao.com/a6450237670911852814/#p=1"
        
        Alamofire.request(url).responseString { (response) in
            guard response.result.isSuccess else {
                return
            }
            if let value = response.result.value {
                if value.contains("<script>var BASE_DATA =") {
                    // 获取 图片链接数组
                    let startIndex = value.range(of: "\"sub_images\":")!.upperBound
                    let endIndex = value.range(of: ",\"max_img_width\"")!.lowerBound
                    let range = Range(uncheckedBounds: (lower: startIndex, upper: endIndex))
                    let BASE_DATA = value.substring(with: range)
                    let data = BASE_DATA.data(using: String.Encoding.utf8)! as Data
                    let dict = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as! [AnyObject]
                    var images = [NewsDetailImage]()
                    for image in dict! {
                        let img = NewsDetailImage(dict: image as! [String: AnyObject])
                        images.append(img)
                    }
                    // 获取 子标题
                    let titleStartIndex = value.range(of: "\"sub_abstracts\":")!.upperBound
                    let titlEndIndex = value.range(of: ",\"sub_titles\"")!.lowerBound
                    let titleRange = Range(uncheckedBounds: (lower: titleStartIndex, upper: titlEndIndex))
                    let sub_abstracts = value.substring(with: titleRange)
                    let titleData = sub_abstracts.data(using: String.Encoding.utf8)! as Data
                    let subAbstracts = try? JSONSerialization.jsonObject(with: titleData, options: .mutableContainers) as! [String]
                    var abstracts = [String]()
                    for string in subAbstracts! {
                        abstracts.append(string)
                    }
                    completionHandler(images, abstracts)
                }
            }
        }
    }
    
    /// 获取图片新闻详情评论
    class func loadNewsDetailImageComments(offset: Int, completionHandler:@escaping (_ comments: [NewsDetailImageComment])->()) {
        let url = BASE_URL + "article/v2/tab_comments/?"
        let params = ["offset": offset,
                      "item_id": 6450240420034118157,
                      "group_id": 6450237670911852814] as [String : AnyObject]
        Alamofire.request(url, parameters: params).responseJSON { (response) in
            guard response.result.isSuccess else {
                return
            }
            if let value = response.result.value {
                let json = JSON(value)
                if let data = json["data"].arrayObject {
                    var comments = [NewsDetailImageComment]()
                    for dict in data {
                        let commentDict = dict as! [String: AnyObject]
                        let comment = NewsDetailImageComment(dict: commentDict["comment"] as! [String : AnyObject])
                        comments.append(comment)
                    }
                    completionHandler(comments)
                }
            }
        }
    }
    
    /// 获取新闻详情评论
    class func loadNewsDetailComments(offset: Int, weitoutiao: WeiTouTiao, completionHandler:@escaping (_ comments: [NewsDetailImageComment])->()) {
        let url = BASE_URL + "article/v2/tab_comments/?"
        var item_id = ""
        var group_id = ""
        if let itemId = weitoutiao.item_id {
            item_id = "\(itemId)"
        }
        if let groupId = weitoutiao.group_id {
            group_id = "\(groupId)"
        }
        let params = ["offset": offset,
                      "item_id": item_id,
                      "group_id": group_id] as [String : AnyObject]
        Alamofire.request(url, parameters: params).responseJSON { (response) in
            guard response.result.isSuccess else {
                return
            }
            if let value = response.result.value {
                let json = JSON(value)
                if let data = json["data"].arrayObject {
                    var comments = [NewsDetailImageComment]()
                    for dict in data {
                        let commentDict = dict as! [String: AnyObject]
                        let comment = NewsDetailImageComment(dict: commentDict["comment"] as! [String : AnyObject])
                        comments.append(comment)
                        
                    }
                    completionHandler(comments)
                }
            }
        }
    }
    
    /// 获取新闻详情相关新闻
    class func loadNewsDetailRelateNews(fromCategory: String, weitoutiao: WeiTouTiao, completionHandler:@escaping (_ relateNews: [WeiTouTiao], _ labels: [NewsDetailLabel], _ userLike: UserLike?, _ appInfo: NewsDetailAPPInfo?) -> ()) {
//        let url = BASE_URL + "2/article/information/v21/?"
//        let params = ["device_id": device_id,
//                      "article_page": weitoutiao.article_type!,
//                      "aggr_type": weitoutiao.aggr_type!,
//                      "latitude": "",
//                      "longitude": "",
//                      "iid": IID,
//                      "item_id": weitoutiao.item_id!,
//                      "group_id": weitoutiao.group_id!,
//                      "device_platform": "iphone",
//                      "from_category": fromCategory] as [String : AnyObject]
        let url = "https://is.snssdk.com/2/article/information/v21/?version_code=6.2.6&app_name=news_article&vid=712DF629-3ED9-4FD0-92DA-ADA33E32EE83&device_id=24694333167&channel=App%20Store&resolution=640*1136&aid=13&ab_version=157646,158751,159670,160288,158954,160774,155241,151126,128826,157001,159623,155247,159165,134127,158531,152027,125174,160445,156262,157852,159226,157295,152954,31651,160816,131207,160615,145585,159558,157554,152582,160240,159250,151115&ab_feature=z2&ab_group=z2&openudid=ceeefaff2ed11a55914a25876b4987ce421a71c8&live_sdk_version=1.6.5&idfv=712DF629-3ED9-4FD0-92DA-ADA33E32EE83&ac=WIFI&os_version=9.3.2&ssmix=a&device_platform=iphone&iid=13142832814&ab_client=a1,f2,f7,e1&device_type=iPhone%205S&idfa=12D3CE1F-D56F-4DFD-9896-A4379014B6BE&article_page=0&group_id=6448876339114164493&device_id=24694333167&longitude=120.1924940751782&aggr_type=1&latitude=30.19549026036954&item_id=6448329201031315981&from_category=__all__"
//        , parameters: params
        Alamofire.request(url).responseJSON { (response) in
            guard response.result.isSuccess else {
                return
            }
            if let value = response.result.value {
                let json = JSON(value)
                if let data = json["data"].dictionary {
                    var relateNews = [WeiTouTiao]()
                    var labels = [NewsDetailLabel]()
                    var userLike: UserLike?
                    var appInfo: NewsDetailAPPInfo?
                    // ---------- 暂时只找到两种情况,后面再补充 ---------------
                    // article_type 分为不同情况，0 和 1 ，返回的数据类型也不一样
                    if weitoutiao.article_type! == 0 {
                        // ordered_info 对应新闻详情顶部的 新闻类别按钮，新欢，不喜欢按钮，app 广告， 相关新闻
                        // ordered_info是一个数组，数组内容不定，根据其中的 name 来判断对应的字典
                        if let ordered_info = data["ordered_info"] {
                            if ordered_info.count > 0 { // 说明 ordered_info 有数据
                                for orderInfo in ordered_info.array! { // 遍历，根据 name 来判断
                                    let ordered = orderInfo.dictionary!
                                    let name = ordered["name"]!.string!
                                    if name == "labels" { // 新闻相关类别,数组
                                        if let orders = ordered["data"] {
                                            for dict in orders.arrayObject! {
                                                let label = NewsDetailLabel(dict: dict as! [String: AnyObject])
                                                labels.append(label)
                                            }
                                        }
                                    } else if name == "like_and_rewards" { // 喜欢 / 不喜欢  字典
                                        userLike = UserLike(dict: ordered["data"]!.dictionaryObject! as [String: AnyObject])
                                    } else if name == "ad" { // 广告， 字典
                                        let appData = ordered["data"]!.dictionary
                                        // 有两种情况，一种 app，一种 mixed
                                        if let app = appData!["app"]?.dictionaryObject {
                                            appInfo = NewsDetailAPPInfo(dict: app as [String: AnyObject])
                                        } else if let mixed = appData!["mixed"]?.dictionaryObject {
                                            appInfo = NewsDetailAPPInfo(dict: mixed as [String: AnyObject])
                                        }
                                    } else if name == "related_news" { // 相关新闻  数组
                                        if let orders = ordered["data"] {
                                            for dict in orders.arrayObject! {
                                                let relatenews = WeiTouTiao(dict: dict as! [String: AnyObject])
                                                relateNews.append(relatenews)
                                            }
                                        }
                                        
                                    }
                                }
                            }
                        }
                    } else if weitoutiao.article_type! == 1 { // 可能是视频
                        if let relatedVideoToutiao = data["related_video_toutiao"] {
                            for dict in relatedVideoToutiao.arrayObject! {
                                let news = WeiTouTiao(dict: dict as! [String: AnyObject])
                                relateNews.append(news)
                            }
                        }
                    }
                    completionHandler(relateNews, labels, userLike, appInfo)
                }
            }
        }
    }
    
    // 获取今日头条的视频真实链接可参考下面的博客
    // http://blog.csdn.net/dianliang01/article/details/73163086
    /// 解析视频的真实链接
    class func parseVideoRealURL(video_id: String, completionHandler:@escaping (_ realVideo: RealVideo)->()) {
        let r = arc4random() // 随机数
        let url: NSString = "/video/urls/v/1/toutiao/mp4/\(video_id)?r=\(r)" as NSString
        let data: NSData = url.data(using: String.Encoding.utf8.rawValue)! as NSData
        var crc32 = data.getCRC32() // 使用 crc32 校验
        if crc32 < 0 { // crc32 的值可能为负数
            crc32 += 0x100000000
        }
        // 拼接
        let realURL = "http://i.snssdk.com/video/urls/v/1/toutiao/mp4/\(video_id)?r=\(r)&s=\(crc32)"
        Alamofire.request(realURL).responseJSON { (response) in
            guard response.result.isSuccess else {
                return
            }
            if let value = response.result.value {
                let json = JSON(value)
                let dict = json["data"].dictionaryObject
                let video = RealVideo(dict: dict! as [String : AnyObject])
                completionHandler(video)
            }
        }
    }
    
    /// 获取头条号 关注
    class func loadEntryList(completionHandler:@escaping (_ concerns: [ConcernToutiaohao])->()) {
        let url = BASE_URL + "entry/list/v1/?"
        let params = ["device_id": device_id,
                      "iid": IID]
        Alamofire.request(url, parameters: params).responseJSON { (response) in
            guard response.result.isSuccess else {
                return
            }
            if let value = response.result.value {
                let json = JSON(value)
                if let data = json["data"].arrayObject {
                    var concerns = [ConcernToutiaohao]()
                    for item in data {
                        let concern = ConcernToutiaohao(dict: item as! [String : AnyObject])
                        concerns.append(concern)
                    }
                    completionHandler(concerns)
                }
            }
        }
    }
    
    
    /// -------------------------- 视 频 video --------------------------
    
    /// 获取视频顶部标题内容
    class func loadVideoTitlesData(completionHandler:@escaping (_ videoTitles: [TopicTitle], _ videoTopicVCs: [VideoTopicController])->()) {
        let url = BASE_URL + "video_api/get_category/v1/?"
        let params = ["device_id": device_id,
                      "iid": IID]
        Alamofire.request(url, parameters: params).responseJSON { (response) in
            guard response.result.isSuccess else {
                return
            }
            if let value = response.result.value {
                let json = JSON(value)
                if let data = json["data"].arrayObject {
                    var titles = [TopicTitle]()
                    var videoTopicVCs = [VideoTopicController]()
                    // 添加推荐标题
                    let recommendDict = ["category": "video", "name": "推荐"]
                    let recommend = TopicTitle(dict: recommendDict as [String : AnyObject])
                    titles.append(recommend)
                    // 添加控制器
                    let firstVC = VideoTopicController()
                    firstVC.videoTitle = recommend
                    videoTopicVCs.append(firstVC)
                    for dict in data {
                        let title = TopicTitle(dict: dict as! [String: AnyObject])
                        let videoTopicVC = VideoTopicController()
                        videoTopicVC.videoTitle = title
                        videoTopicVCs.append(videoTopicVC)
                        titles.append(title)
                    }
                    completionHandler(titles, videoTopicVCs)
                }
            }
        }
    }
    
    // --------------------------  微  头  条  --------------------------
    
    /// 获取微头条数据
    class func loadWeiTouTiaoData(completionHandler: @escaping (_ weitoutiaos: [WeiTouTiao]) -> ()) {
        let url = BASE_URL + "api/news/feed/v54/?"
        let params = ["iid": IID,
                      "category": "weitoutiao",
                      "count": 20,
                      "device_id": device_id] as [String : Any]
        Alamofire.request(url, parameters: params).responseJSON { (response) in
            guard response.result.isSuccess else {
                return
            }
            if let value = response.result.value {
                let json = JSON(value)
                guard json["message"].string == "success" else {
                    return
                }
                guard let dataJSONs = json["data"].array else {
                    return
                }
                var weitoutiaos = [WeiTouTiao]()
                for dataJSON in dataJSONs {
                    if let content = dataJSON["content"].string {
                        let data = content.data(using: String.Encoding.utf8)! as Data
                        let dict = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
                        let weitoutiao = WeiTouTiao(dict: dict as! [String : AnyObject])
                        weitoutiaos.append(weitoutiao)
                    }
                }
                completionHandler(weitoutiaos)
            }
        }
    }
    
    /// 点击了关注按钮
    class func loadFollowInfo(user_id: Int, completionHandler: @escaping (_ isFllowing: Bool)->()) {
        let url = BASE_URL + "2/relation/follow/v2/?"
        let params = ["iid": IID,
                      "user_id": user_id,
                      "device_id": device_id] as [String : Any]
        Alamofire.request(url, parameters: params).responseJSON { (response) in
            guard response.result.isSuccess else {
                return
            }
            if let value = response.result.value {
                let json = JSON(value)
                guard json["message"].string == "success" else {
                    return
                }
                guard let data = json["data"].dictionary else {
                    return
                }
                guard data["description"]?.string == "关注成功" else {
                    return
                }
                if let user = data["user"]?.dictionaryObject {
                    let user_info = WTTUser(dict: user as [String : AnyObject])
                    completionHandler(user_info.is_following!)
                }
            }
        }
        
    }
    
    /// 点击了取消关注按钮
    class func loadUnfollowInfo(user_id: Int, completionHandler: @escaping (_ isFllowing: Bool)->()) {
        let url = BASE_URL + "/2/relation/unfollow/?"
        let params = ["iid": IID,
                      "user_id": user_id,
                      "device_id": device_id] as [String : Any]
        Alamofire.request(url, parameters: params).responseJSON { (response) in
            guard response.result.isSuccess else {
                return
            }
            if let value = response.result.value {
                let json = JSON(value)
                guard json["message"].string == "success" else {
                    return
                }
                guard let data = json["data"].dictionary else {
                    return
                }
                if let user = data["user"]?.dictionaryObject {
                    let user_info = WTTUser(dict: user as [String : AnyObject])
                    completionHandler(user_info.is_following!)
                }
            }
        }
        
    }
    
    // --------------------------------- 我的 mine  ---------------------------------
    /// 我的界面 cell 数据
    class func loadMineCellData(completionHandler: @escaping (_ sectionsArray: [AnyObject])->()) {
        let url = BASE_URL + "user/tab/tabs/?"
        let params = ["iid": IID]
        Alamofire.request(url, parameters: params).responseJSON { (response) in
            guard response.result.isSuccess else {
                return
            }
            if let value = response.result.value {
                let json = JSON(value)
                guard json["message"].string == "success" else {
                    return
                }
                if let data = json["data"].dictionary {
                    if let sections = data["sections"]?.arrayObject {
                        var sectionArray = [AnyObject]()
                        for section in sections {
                            var rows = [MineCellModel]()
                            for row in section as! [AnyObject] {
                                let mineCell = MineCellModel(dict: row as! [String : AnyObject])
                                rows.append(mineCell)
                            }
                            sectionArray.append(rows as AnyObject)
                        }
                        completionHandler(sectionArray)
                    }
                }
            }
        }
    }
    
    /// 我的关注 
    class func loadMyFollow(completionHandler: @escaping (_ concerns: [MyConcern])->()) {
        let url = BASE_URL + "concern/v2/follow/my_follow/?"
        let params = ["device_id": device_id]
        Alamofire.request(url, parameters: params).responseJSON { (response) in
            guard response.result.isSuccess else {
                return
            }
            if let value = response.result.value {
                let json = JSON(value)
                guard json["message"].string == "success" else {
                    return
                }
                if let datas = json["data"].arrayObject {
                    var concerns = [MyConcern]()
                    for data in datas {
                        let myConcern = MyConcern(dict: data as! [String: AnyObject])
                        concerns.append(myConcern)
                    }
                    
                    completionHandler(concerns)
                }
            }
        }
    }
    
    /// 关注详情
    class func loadOneFollowDetail(userId: Int, completionHandler: @escaping (_ follewDetail: FollowDetail)->()) {
        let url = BASE_URL + "user/profile/homepage/v3/?"
        let params = ["user_id": userId] as [String : Any]
        Alamofire.request(url, parameters: params).responseJSON { (response) in
            guard response.result.isSuccess else {
                return
            }
            if let value = response.result.value {
                let json = JSON(value)
                guard json["message"].string == "success" else {
                    return
                }
                let followDetail = FollowDetail(dict: json["data"].dictionaryObject! as [String : AnyObject])
                completionHandler(followDetail)
            }
        }
    }
}
