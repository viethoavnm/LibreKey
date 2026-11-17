//
//  RimeEngine.h
//  LibreKey
//
//  Created for Simplified Chinese Pinyin integration.
//

#ifndef RimeEngine_h
#define RimeEngine_h

#include <string>
#include <vector>
#include <rime_api.h>

struct RimeCandidateItem {
    std::string text;
    std::string comment;
};

struct RimeUIState {
    bool has_menu = false;
    std::string preedit;
    int highlighted_index = 0;
    int num_candidates = 0;
    int page_size = 5;
    int page_no = 0;
    bool is_last_page = false;
    std::vector<RimeCandidateItem> candidates;
};

class RimeEngine {
public:
    static RimeEngine& instance();

    bool init(const std::string& shared_dir, const std::string& user_dir);
    void cleanup();
    bool isInitialized() const { return is_initialized_; }

    // Process a key. Returns true if key was handled/consumed by Rime.
    // If commit text is available, out_commit_text will be populated.
    // out_ui_state is updated with current preedit and candidates.
    bool processKey(int keycode, int mask, std::string& out_commit_text, RimeUIState& out_ui_state);

    // Select candidate at 0-based index
    bool selectCandidate(int index, std::string& out_commit_text, RimeUIState& out_ui_state);

    // Page up / page down
    bool changePage(bool forward, RimeUIState& out_ui_state);

    // Clear buffer / cancel
    void clearComposition();

    // Fetch current UI state
    void fetchUIState(RimeUIState& out_ui_state);

private:
    RimeEngine();
    ~RimeEngine();

    RimeEngine(const RimeEngine&) = delete;
    RimeEngine& operator=(const RimeEngine&) = delete;

    RimeApi* api_ = nullptr;
    RimeSessionId session_id_ = 0;
    bool is_initialized_ = false;
};

#endif // RimeEngine_h
