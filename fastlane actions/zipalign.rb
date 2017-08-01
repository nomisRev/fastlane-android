module Fastlane
  module Actions
    module SharedValues
      ZIPALIGN_CUSTOM_VALUE = :ZIPALIGN_CUSTOM_VALUE
    end

    class ZipalignAction < Action
      DEFAULT_APK_PATH = File.join('app', 'build', 'outputs', 'apk', '*release.apk')

      def self.run(params)
        apk_path = params[:apk_path]
        UI.user_error!("Couldn't find #{ZipalignAction::DEFAULT_APK_PATH}") unless apk_path

        android_sdk_paths = [
          ENV['ANDROID_HOME'],
          ENV['ANDROID_SDK_ROOT'],
          '/usr/local/Cellar/android-sdk',
          '/Library/Android/sdk',
          '~/Library/Android/sdk',
          '/opt/android-sdk',
          '/usr/lib/android-sdk',
          '/opt/android-sdk-linux'
        ].compact

        zipalign = nil
        android_sdk_paths.each {|path|
          zipalign = Dir[File.join(path, '**', 'zipalign')].last
          break if zipalign
        }
        UI.user_error!("Couldn't find zipalign in #{android_sdk_paths.join(', ')}") unless zipalign

        cmd = [zipalign, '-c 4', apk_path]
        Fastlane::Actions.sh(cmd, log: false, error_callback: -> (_) {
          new_name = apk_path.gsub('.apk', '-unaligned.apk')
          File.rename(apk_path, new_name)

          cmd = [zipalign, '-v -f 4', new_name, apk_path]
          Fastlane::Actions.sh(cmd, log: true)
        })

        UI.message('Input apk is aligned')
      end

      #####################################################
      # @!group Documentation
      #####################################################
      def self.description
        "Zipalign an apk. Input apk is renamed '*-unaligned.apk'"
      end

      def self.available_options
        apk_path_default =
          Actions.lane_context[SharedValues::GRADLE_APK_OUTPUT_PATH] ||
          Dir['*.apk' || ZipalignAction::DEFAULT_APK_PATH].last

        [
          FastlaneCore::ConfigItem.new(
            key: :apk_path,
            env_name: 'INPUT_APK_PATH',
            description: 'Path to your APK file that you want to align',
            default_value: apk_path_default,
            optional: true
          )
        ]
      end

      def self.authors
        'nomisRev'
      end

      def self.is_supported?(platform)
        platform == :android
      end
    end
  end
end
