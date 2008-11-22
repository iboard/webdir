ActionController::Routing::Routes.draw do |map|

  map.passwords 'passwords', :controller => 'administration', :action => 'passwords'
  map.file_action   'file_action', :controller => 'administration', :action => 'file_action', :method => :post
  map.change_folder 'change_folder/:path',       :controller => 'administration', :action => 'index'
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'

  map.set_user_path ':path', :controller => 'administration', :action => 'set_user_path'  
  map.download 'download/:file', :controller => 'administration', :action => 'download'  
  map.root :controller => 'administration', :action => 'index', :path => '_ROOT_'

end
