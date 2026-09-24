//
//  OKEngineCorpus.h
//  OpenKeyTests
//
//  Runs a table of "keys -> expected text" rows through OKTypeKeys and adds
//  up how many came out right and how many broke a safety rule.
//

#ifndef OKEngineCorpus_h
#define OKEngineCorpus_h

#include <string>
#include <vector>
#include "OKEngineTypist.h"

//Input: one row of a corpus file.
struct OKCorpusRow {
    std::string keys;
    std::string expected;
};

//Output: the verdict on a whole corpus.
struct OKCorpusReport {
    int rows = 0;
    int passed = 0;
    int overDeletes = 0;            //rows that deleted into the text before them
    int controlChars = 0;           //rows that made the host insert a control character
    std::vector<std::string> failures;  //"keys -> got (want expected)", for the log
};

//Reads a UTF-8 file of keys<TAB>expected lines. Blank lines and lines starting
//with # are skipped. A missing file gives no rows.
std::vector<OKCorpusRow> OKLoadCorpus(const std::string& path);

//Types every row after `prefix`, each from a fresh engine. The prefix is
//expected in front of the result too, and deleting into it is an over-delete.
OKCorpusReport OKRunCorpus(const std::vector<OKCorpusRow>& rows,
                           const OKTypingSettings& settings = OKTypingSettings(),
                           const std::string& prefix = "pp ");

#endif
