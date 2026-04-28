# frozen_string_literal: true

def generate_module_map(installer)
  pod_name_to_find = 'DanceUI'

  # Find the corresponding pod target from the installer
  pod_target = installer.pods_project.native_targets.find { |target| target.name == pod_name_to_find }

  # Ensure we found the target, in case the pod name is wrong or the pod has no target
  if pod_target
    public_headers = []
    private_headers = []

    # Get the headers build phase of this target
    headers_phase = pod_target.headers_build_phase

    # Iterate over all files in the headers build phase
    headers_phase.files.each do |pbx_build_file|
      # The settings attribute of pbx_build_file contains the file's visibility (Public, Private, Project)
      settings = pbx_build_file.settings

      # Check if settings exist and contain 'ATTRIBUTES'
      if settings && settings['ATTRIBUTES']
        # Get the real path of the file
        file_path = pbx_build_file.file_ref.real_path.to_s

        if settings['ATTRIBUTES'].include?('Public')
          public_headers << file_path
        elsif settings['ATTRIBUTES'].include?('Private')
          private_headers << file_path
        end
      end
    end

    # Filter out the umbrella header itself
    public_headers.reject! { |h| h.end_with?('DanceUI-umbrella.h') }
    private_headers.reject! { |h| h.end_with?('DanceUI-Private.h') }
    private_headers.reject! { |h| h.end_with?('.hpp') }

    # Define the paths for the generated umbrella headers
    script_dir = File.dirname(__FILE__)
    public_umbrella_header_path = File.expand_path(File.join(script_dir, '../Sources/DanceUIShims/Public/DanceUI-umbrella.h'))
    private_umbrella_header_path = File.expand_path(File.join(script_dir, '../Sources/DanceUIShims/Private/DanceUI-Private.h'))

    # Generate and write the public umbrella header
    public_content = umbrella_header_content(public_headers, pod_name_to_find)
    File.write(public_umbrella_header_path, public_content)
    puts "✅ Update public umbrella header at #{public_umbrella_header_path}"

    # Generate and write the private umbrella header
    private_content = umbrella_header_content(private_headers, pod_name_to_find)
    File.write(private_umbrella_header_path, private_content)
    puts "✅ Generated private umbrella header at #{private_umbrella_header_path}"
  else
    puts "⚠️ Warning: Could not find pod target named '#{pod_name_to_find}'."
  end
end

# Template for the umbrella header file
def umbrella_header_content(headers, pod_name)
  header_imports = headers.map { |h| File.basename(h) }.sort.map { |h| "#import \"#{h}\"" }.join("\n")

  <<~HEREDOC
    #ifdef __OBJC__
    #import <UIKit/UIKit.h>
    #else
    #ifndef FOUNDATION_EXPORT
    #if defined(__cplusplus)
    #define FOUNDATION_EXPORT extern "C"
    #else
    #define FOUNDATION_EXPORT extern
    #endif
    #endif
    #endif

    #{header_imports}

    FOUNDATION_EXPORT double #{pod_name}VersionNumber;
    FOUNDATION_EXPORT const unsigned char #{pod_name}VersionString[];
  HEREDOC
end
