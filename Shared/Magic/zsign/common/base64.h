 * Proprietary Software License Version 1.0
 *
 * Copyright (C) 2025 BDG
 *
<<<<<<< HEAD
 * Backdoor App Signer is proprietary software. You may not use, modify, or distribute it except as expressly permitted under the terms of the Proprietary Software License.

 *
 * Copyright (C) 2025 BDG
 *
<<<<<<< HEAD
 * Backdoor App Signer is proprietary software. You may not use, modify, or distribute it except as expressly permitted under the terms of the Proprietary Software License.

/*
 * Proprietary Software License Version 1.0
 *
 * Copyright (C) 2025 BDG
 *
 * Backdoor App Signer is proprietary
 * software. You may not use, modify, or distribute it except as expressly permitted under the terms of the Proprietary
 * Software License.
 */

#pragma once

#include <string>
#include <vector>

using namespace std;

class ZBase64 {
public:
    ZBase64(void);
    ~ZBase64(void);

public:
    const char *Encode(const char *szSrc, int nSrcLen = 0);
    const char *Encode(const string &strInput);
    const char *Decode(const char *szSrc, int nSrcLen = 0, int *pDecLen = NULL);
    const char *Decode(const char *szSrc, string &strOutput);

private:
    inline int GetB64Index(char ch);
    inline char GetB64char(int nIndex);

private:
    vector<char *> m_arrDec;
    vector<char *> m_arrEnc;
};
