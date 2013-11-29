//
//  md5.h
//  System Scope
//
//  Created by Scott Goldman on 4/20/17.
//  Copyright © 2017 Scott J. Goldman. All rights reserved.
//

#ifndef md5_h
#define md5_h

#if defined(__APPLE__)
#include <CommonCrypto/CommonDigest.h>
#define MD5_DIGEST_LENGTH 16
#define MD5(x,y,z) CC_MD5(x,(CC_LONG)y,z)
#else
#include <openssl/md5.h>
#endif


#endif /* md5_h */
