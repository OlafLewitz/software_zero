module ApplicationHelper
  def banner_image
    cookies[:banner_image] ||= random_banner_image
  end

  # eg: "/assets/skins/appstoreforyourhead/headers/2.png"
  def random_banner_image
    headers_paths = Dir.chdir(Rails.root.join('app/assets/images')) { Dir["skins/appstoreforyourhead/headers/*.png"] }
    headers_paths.map!{ |path| File.join('/assets', path) }
    headers_paths.sample
  end
end
