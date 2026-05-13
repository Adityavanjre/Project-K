# Download open source dependencies (Boost, Swift) before pod resolution
# This runs at require time, BEFORE CocoaPods resolves path: dependencies
_bootstrap_root_path = `git rev-parse --show-toplevel`.strip
_init_script = File.join(_bootstrap_root_path, 'init.sh')
if File.exist?(_init_script)
  _deps_dir = File.join(_bootstrap_root_path, '..', 'DanceUIDependencies')
  if Dir.exist?(_deps_dir)
    print("[DanceUI bootstrap.rb] Open source dependencies already exist, skipping download.\n")
  else
    print("[DanceUI bootstrap.rb] Downloading open source dependencies...\n")
    unless system("bash", _init_script)
      raise "[bootstrap.rb] init.sh failed"
    end
  end
end

def is_git_worktree?(root_path)
  git_dir = root_path + '/.git'
  File.file?(git_dir)
end

def cleanup_legacy_linter_hooks(root_path)
	hooks_dir = root_path + '/.git/hooks'
	unless Dir.exist?(hooks_dir)
		print("\tGit hooks directory not found, skipping legacy linter hook cleanup\n")
		return
	end

	legacy_markers = [
		'tidy-buddy',
		'utils/LinterKit/bootstrap'
	]

	%w[pre-commit pre-push].each do |hook_name|
		hook_path = File.join(hooks_dir, hook_name)
		next unless File.file?(hook_path)

		begin
			content = File.read(hook_path)
		rescue => e
			print("\tFailed to read \\#{hook_path} during legacy linter hook cleanup: \\#{e}\n")
			next
		end

		unless legacy_markers.any? { |marker| content.include?(marker) }
			next
		end

		backup_path = hook_path + '.tidy-buddy.bak'
		if File.exist?(backup_path)
			print("\tLegacy linter hook already backed up at \\#{backup_path}, removing current hook \\#{hook_path}\n")
			File.delete(hook_path) rescue nil
		else
			print("\tBacking up legacy linter hook \\#{hook_path} to \\#{backup_path}\n")
			begin
				File.rename(hook_path, backup_path)
			rescue => e
				print("\tFailed to back up legacy linter hook \\#{hook_path}: \\#{e}\n")
			end
		end
	end
end

def bootstrap
  print("[DanceUI bootstrap.rb] begin bootstrap\n")

  root_path = `git rev-parse --show-toplevel`.strip

  # Clean up legacy tidy-buddy / LinterKit based hooks in existing working copies
  cleanup_legacy_linter_hooks(root_path)
  
  # Continue with any other bootstrap tasks here
  print("\tBootstrap completed successfully\n")
end
