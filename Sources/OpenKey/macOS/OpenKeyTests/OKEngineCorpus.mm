//
//  OKEngineCorpus.mm
//  OpenKeyTests
//

#include "OKEngineCorpus.h"
#include <fstream>

std::vector<OKCorpusRow> OKLoadCorpus(const std::string& path) {
    std::vector<OKCorpusRow> rows;
    std::ifstream in(path);
    std::string line;
    while (std::getline(in, line)) {
        if (!line.empty() && line.back() == '\r')
            line.pop_back();
        if (line.empty() || line[0] == '#')
            continue;
        size_t tab = line.find('\t');
        if (tab == std::string::npos)
            continue;
        rows.push_back({line.substr(0, tab), line.substr(tab + 1)});
    }
    return rows;
}

OKCorpusReport OKRunCorpus(const std::vector<OKCorpusRow>& rows,
                           const OKTypingSettings& settings,
                           const std::string& prefix) {
    return OKCorpusReport();
}
