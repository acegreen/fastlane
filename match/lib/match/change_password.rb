require_relative 'module'

module Match
  # These functions should only be used while in (UI.) interactive mode
  class ChangePassword
    def self.update(params: nil)
      ensure_ui_interactive

      to ||= ChangePassword.ask_password(message: "New passphrase for Git Repo: ", confirm: true)

      # Choose the right storage and encryption implementations
      storage = Storage::Interface.storage_class_for_storage_mode(params[:storage_mode]).new

      storage.configure(git_url: params[:git_url],
                    shallow_clone: params[:shallow_clone],
                    skip_docs: params[:skip_docs],
                    branch: params[:git_branch],
                    git_full_name: params[:git_full_name],
                    git_user_email: params[:git_user_email],
                    clone_branch_directly: params[:clone_branch_directly])
      storage.download

      encryption = Encryption::Interface.encryption_class_for_storage_mode(params[:storage_mode]).new(
        git_url: storage.git_url,
        working_directory: storage.working_directory
      )
      encryption.decrypt_files

      encryption.clear_password
      encryption.store_password(to)

      message = "[fastlane] Changed passphrase"
      encryption.encrypt_files
      storage.save_changes!(custom_message: message)
    end

    # This method is called from both here, and from `openssl.rb`
    def self.ask_password(message: "Passphrase for Git Repo: ", confirm: nil)
      ensure_ui_interactive
      loop do
        password = UI.password(message)
        if confirm
          password2 = UI.password("Type passphrase again: ")
          if password == password2
            return password
          end
        else
          return password
        end
        UI.error("Passphrases differ. Try again")
      end
    end

    def self.ensure_ui_interactive
      raise "This code should only run in interactive mode" unless UI.interactive?
    end

    private_class_method :ensure_ui_interactive
  end
end
