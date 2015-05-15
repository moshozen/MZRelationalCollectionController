version = '0.0.1'

Pod::Spec.new do |s|
  s.name         = "MZRelationalCollectionController"
  s.version      = version
  s.summary      = "Controller to expose KVO on a collection relation and its objects"

  s.description  = <<-DESC
                    MZRelationalCollectionController manages KVO on a named relation of an object,
                    providing delegate notification on various changes to the content of the
                    relation, as well as on changes to specified attributes of the objects in the
                    relation collection. Very loosely inspired by NSArrayController and
                    NSFetchedResultsController
                   DESC

  s.homepage     = "https://github.com/moshozen/MZRelationalCollectionController"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }

  s.author             = { "Mat Trudel" => "mat@geeky.net" }
  s.social_media_url   = "http://twitter.com/mattrudel"

  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/moshozen/MZRelationalCollectionController.git", :tag => version }
  s.source_files  = "Classes", "Classes/**/*.{h,m}"
end