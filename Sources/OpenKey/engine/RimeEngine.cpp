//
//  RimeEngine.cpp
//  LibreKey
//
//  Created for Simplified Chinese Pinyin integration.
//

#include "RimeEngine.h"
#include <iostream>

RimeEngine::RimeEngine() {
    api_ = rime_get_api();
}

RimeEngine::~RimeEngine() {
    cleanup();
}

RimeEngine& RimeEngine::instance() {
    static RimeEngine s_instance;
    return s_instance;
}

bool RimeEngine::init(const std::string& shared_dir, const std::string& user_dir) {
    if (is_initialized_) {
        return true;
    }

    if (!api_) {
        api_ = rime_get_api();
        if (!api_) return false;
    }

    RIME_STRUCT(RimeTraits, traits);
    traits.shared_data_dir = shared_dir.c_str();
    traits.user_data_dir = user_dir.c_str();
    traits.distribution_name = "Rime";
    traits.distribution_code_name = "LibreKey";
    traits.app_name = "rime.librekey";

    api_->setup(&traits);
    api_->initialize(&traits);
    api_->start_maintenance(false);
    api_->join_maintenance_thread();

    session_id_ = api_->create_session();
    if (!session_id_) {
        return false;
    }

    api_->select_schema(session_id_, "pinyin_simp");
    is_initialized_ = true;
    return true;
}

void RimeEngine::cleanup() {
    if (is_initialized_ && api_) {
        if (session_id_) {
            api_->destroy_session(session_id_);
            session_id_ = 0;
        }
        api_->finalize();
        is_initialized_ = false;
    }
}

void RimeEngine::fetchUIState(RimeUIState& out_ui_state) {
    out_ui_state = RimeUIState();
    if (!is_initialized_ || !session_id_ || !api_) return;

    RIME_STRUCT(RimeContext, ctx);
    if (api_->get_context(session_id_, &ctx)) {
        if (ctx.composition.preedit && ctx.composition.preedit[0] != '\0') {
            out_ui_state.preedit = ctx.composition.preedit;
        }

        if (ctx.menu.num_candidates > 0) {
            out_ui_state.has_menu = true;
            out_ui_state.num_candidates = ctx.menu.num_candidates;
            out_ui_state.highlighted_index = ctx.menu.highlighted_candidate_index;
            out_ui_state.page_size = ctx.menu.page_size > 0 ? ctx.menu.page_size : 5;
            out_ui_state.page_no = ctx.menu.page_no;
            out_ui_state.is_last_page = ctx.menu.is_last_page ? true : false;

            for (int i = 0; i < ctx.menu.num_candidates; ++i) {
                RimeCandidateItem cand;
                if (ctx.menu.candidates[i].text) {
                    cand.text = ctx.menu.candidates[i].text;
                }
                if (ctx.menu.candidates[i].comment) {
                    cand.comment = ctx.menu.candidates[i].comment;
                }
                out_ui_state.candidates.push_back(cand);
            }
        } else if (!out_ui_state.preedit.empty()) {
            out_ui_state.has_menu = true;
        }
        api_->free_context(&ctx);
    }
}

bool RimeEngine::processKey(int keycode, int mask, std::string& out_commit_text, RimeUIState& out_ui_state) {
    out_commit_text.clear();
    if (!is_initialized_ || !session_id_ || !api_) {
        return false;
    }

    Bool handled = api_->process_key(session_id_, keycode, mask);

    // Check if there is commit text
    RIME_STRUCT(RimeCommit, commit);
    if (api_->get_commit(session_id_, &commit)) {
        if (commit.text && commit.text[0] != '\0') {
            out_commit_text = commit.text;
        }
        api_->free_commit(&commit);
    }

    fetchUIState(out_ui_state);
    return handled ? true : false;
}

bool RimeEngine::selectCandidate(int index, std::string& out_commit_text, RimeUIState& out_ui_state) {
    out_commit_text.clear();
    if (!is_initialized_ || !session_id_ || !api_) {
        return false;
    }

    Bool handled = api_->select_candidate_on_current_page(session_id_, index);
    if (!handled) {
        // Fallback: simulate pressing '1' + index
        handled = api_->process_key(session_id_, '1' + index, 0);
    }

    RIME_STRUCT(RimeCommit, commit);
    if (api_->get_commit(session_id_, &commit)) {
        if (commit.text && commit.text[0] != '\0') {
            out_commit_text = commit.text;
        }
        api_->free_commit(&commit);
    }

    fetchUIState(out_ui_state);
    return handled ? true : false;
}

bool RimeEngine::changePage(bool forward, RimeUIState& out_ui_state) {
    if (!is_initialized_ || !session_id_ || !api_) {
        return false;
    }
    Bool handled = api_->change_page(session_id_, forward ? False : True);
    fetchUIState(out_ui_state);
    return handled ? true : false;
}

void RimeEngine::clearComposition() {
    if (is_initialized_ && session_id_ && api_) {
        api_->clear_composition(session_id_);
    }
}
