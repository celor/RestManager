Pod::Spec.new do |s|
s.name         = "RestManager"
s.version      = "0.0.1"
s.summary      = "A simple Rest Manager which allow you to set rest route and let it make the Mapping from json to nsmanagedobjects"
s.homepage     = "https://github.com/celor/RestManager"
s.license      = "MIT"
s.author       = "Aurélien Scelles"
s.platform     = :ios, "7.0"
s.source       = { :git => "https://github.com/celor/RestManager.git" }
s.requires_arc = true
s.source_files  = "Classes/**/*.{h,m}" , "Extensions/RestAFNetworking.{h,m}"
s.dependency "AFNetworking", "~> 2.5.4"
end
