class UtilController < ApplicationController
        
  def fake_error
    raise RuntimeError, "this is a fake error"   # to test exception notifier
  end

end