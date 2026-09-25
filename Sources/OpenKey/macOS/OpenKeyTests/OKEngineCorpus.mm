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
    OKCorpusReport report;
    for (const OKCorpusRow& row : rows) {
        OKTypingResult result = OKTypeKeys(row.keys, settings, prefix);
        report.rows++;
        if (result.overDeletes > 0)
            report.overDeletes++;
        if (result.controlChars > 0)
            report.controlChars++;

        std::string want = prefix + row.expected;
        if (result.text == want) {
            report.passed++;
        } else {
            //show the row itself, without the prefix every row shares
            std::string got = result.text.compare(0, prefix.size(), prefix) == 0
                ? result.text.substr(prefix.size()) : result.text;
            report.failures.push_back(row.keys + " -> " + got + " (want " + row.expected + ")");
        }
    }
    return report;
}
