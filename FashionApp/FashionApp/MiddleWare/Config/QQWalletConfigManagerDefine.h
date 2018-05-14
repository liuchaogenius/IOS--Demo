//
//  QQWalletConfigManagerDefine.h
//  QQ
//
//  Created by menghuisu on 2017/11/14.
//

/**---------------------  业务接入钱包配置系统需要在下面添加配置key  -------------------------------**/
typedef enum : long {
    QQWalletConfigReqTypeAll     = 0,    //全量配置
//    QQWalletConfigReqTypeGoldMsg = 1<<0,  //句有料配置
} QQWalletConfigReqType;

#define QQWalletConfigKeySessionCache @"session"   //钱包配置Session缓存key
//#define QQWalletConfigKeyGoldMsg   @"gold_msg"  //句有料配置key

/**----------------------------  业务配置内部字段key在下面定义 ------------------------------------**/

/** 句有料配置内部字段key **/
//#define kQQWalletConfigKeyGoldMsgEntry @"entry"
//#define kQQWalletConfigKeyGoldMsgGroupDiscussPopURL @"group_discuss_pop_url"
//#define kQQWalletConfigKeyGoldMsgPanelADs @"panel_ad"


/**----------------------------  业务存储到配置Session中的key映射(配置后台希望Session配置越小越好,太长的key映射为简单的数字字符串) ------------------------------------**/

//#define kQWConfigSessionKey_IsAgreePolicy @"1"  //是否同意钱包首页隐私政策状态key

