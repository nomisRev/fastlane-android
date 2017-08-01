module Fastlane
  module Actions
    module SharedValues
      SIGNED_APK_PATH = :SIGNED_APK_PATH
    end

    class SignApkAction < Action
      DEFAULT_APK_PATH = File.join('app', 'build', 'outputs', 'apk', '*release-unsigned.apk')

      def self.run(params)
        apk_path = params[:apk_path]
        key_alias = params[:alias]
        keystore = params[:keystore_path]
        storepass = params[:storepass]
        keypass = params[:keypass] || storepass
        tsa = params[:tsa]
        signed_apk_path = params[:signed_apk_path]

        UI.user_error!("Couldn't find '#{SignApkAction::DEFAULT_APK_PATH}'") unless apk_path
        UI.user_error!('Need keystore in order to sign apk') unless keystore

        sign_cmd = ['jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1']
        sign_cmd << "-keystore #{keystore}"
        sign_cmd << apk_path
        sign_cmd << key_alias if key_alias
        sign_cmd << "-keypass #{keypass}" if keypass
        sign_cmd << "-storepass #{storepass}" if storepass
        sign_cmd << "-tsa #{tsa}" if tsa

        if not signed_apk_path and apk_path.include?('unsigned')
          signed_apk_path = apk_path.gsub('-unsigned', '')
        end

        if signed_apk_path
          sign_cmd << "-signedjar #{signed_apk_path}"
        end

        Actions.lane_context[SharedValues::SIGNED_APK_PATH] = signed_apk_path
        Fastlane::Actions.sh(sign_cmd, log: true)
      end

      #####################################################
      # @!group Documentation
      #####################################################
      def self.available_options
        apk_path_default =
          Actions.lane_context[SharedValues::GRADLE_APK_OUTPUT_PATH] ||
          Dir['*.apk' || SignApkAction::DEFAULT_APK_PATH].last

        [
          FastlaneCore::ConfigItem.new(
            key: :apk_path,
            env_name: 'apk_path',
            description: 'Path to your APK file that you want to sign',
            default_value: apk_path_default,
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :signed_apk_path,
            env_name: 'SIGNED_APK_PATH',
            description: 'Path to the signed APK file',
            optional: true,
            is_string: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :keystore_path,
            env_name: 'KEYSTORE_PATH',
            description: 'Path to java keystore',
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :alias,
            env_name: 'ALIAS',
            description: 'The alias of the certificate in the keystore to use to sign the apk',
            is_string: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :keypass,
            env_name: 'KEY_PASS',
            description: 'The password used to protect the private key of the keystore entry addressed by the alias specified. If not specified storepass will be used',
            optional: true,
            is_string: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :storepass,
            env_name: 'STORE_PASS',
            description: 'The password which is required to  access  the keystore',
            is_string: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :tsa,
            env_name: 'TIME_STAMPING_AUTHORITHY',
            description: 'The url of the Time Stamping Authority (TSA) used to timestamp the apk signing',
            optional: true,
            is_string: true
          )
        ]
      end

      def self.description
        'Sign a Android apk with a java keystore'
      end

      def self.output
        ['SIGN_APK_PATH', 'Path to your APK file']
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
