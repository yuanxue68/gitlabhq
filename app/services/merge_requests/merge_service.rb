module MergeRequests
  # MergeService class
  #
  # Do git merge and in case of success
  # mark merge request as merged and execute all hooks and notifications
  # Executed when you do merge via GitLab UI
  #
  class MergeService < MergeRequests::BaseService
    attr_reader :merge_request, :source

    def execute(merge_request)
      @merge_request = merge_request

      return log_merge_error('Merge request is not mergeable', true) unless @merge_request.mergeable?

      @source = find_merge_source

      return log_merge_error('No source for merge', true) unless @source

      merge_request.in_locked_state do
        if commit
          after_merge
          success
        else
          log_merge_error('Can not merge changes', true)
        end
      end
    end

    private

    def commit
      committer = repository.user_to_committer(current_user)

      options = {
        message: params[:commit_message] || merge_request.merge_commit_message,
        author: committer,
        committer: committer
      }

      commit_id = repository.merge(current_user, source, merge_request, options)

      if commit_id
        merge_request.update(merge_commit_sha: commit_id)
      else
        merge_request.update(merge_error: 'Conflicts detected during merge')
        false
      end
    rescue GitHooksService::PreReceiveError => e
      merge_request.update(merge_error: e.message)
      false
    rescue StandardError => e
      merge_request.update(merge_error: "Something went wrong during merge: #{e.message}")
      log_merge_error(e.message)
      false
    ensure
      merge_request.update(in_progress_merge_commit_sha: nil)
    end

    def after_merge
      MergeRequests::PostMergeService.new(project, current_user).execute(merge_request)

      if params[:should_remove_source_branch].present? || @merge_request.force_remove_source_branch?
        DeleteBranchService.new(@merge_request.source_project, branch_deletion_user).
          execute(merge_request.source_branch)
      end
    end

    def branch_deletion_user
      @merge_request.force_remove_source_branch? ? @merge_request.author : current_user
    end

    def log_merge_error(message, http_error = false)
      Rails.logger.error("MergeService ERROR: #{merge_request_info} - #{message}")

      error(message) if http_error
    end

    def merge_request_info
      merge_request.to_reference(full: true)
    end

    def find_merge_source
      merge_request.diff_head_sha
    end
  end
end
