Pod::Spec.new do |spec|
  spec.name = "Benji"
  spec.version = "1.2.2"
  spec.summary = "Benji is a lightweight HTTP networking library written in Swift for simple HTTP API requests using JSON and uploading/downloading files."
  spec.homepage = "https://github.com/aa-wong/Benji"
  spec.license = { type: 'MIT', file: 'LICENSE' }
  spec.authors = { "Aaron Wong" => 'aaron@pixelbirddesign.com' }

  spec.platform = :ios, "9.0"
  spec.requires_arc = true
  spec.source = { git: "https://github.com/aa-wong/Benji.git", tag: "v#{spec.version}"}
  spec.source_files = "Benji/**/*.{h, swift}"
  spec.swift_version = '5.0'
  spec.vendored_frameworks = 'Benji.framework'

end
