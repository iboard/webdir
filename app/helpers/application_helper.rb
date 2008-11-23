# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def round_box( width="100%", height="100%", &block ) 
    concat( "<div class='round_box' style='width: #{width}; height: #{height};  text-align: center;'>" +
              "<div class='round_box_top'>" +
                "<div class='round_box_upper_left'></div>"+
                "<div class='round_box_upper_middle'></div>"+
                "<div class='round_box_upper_right'></div>"+
              "</div>" +
              "<div class='round_box_middle'>" +
                "<div class='round_box_left'></div>" +
                "<div class='round_box_main' style='text-align: left; padding: 10px;'>", block.binding )
                   yield
    concat(     "</div>"+
                "<div class='round_box_right'></div>" +
              "</div>"+
              "<div class='round_box_bottom'>" +
                "<div class='round_box_bottom_left'></div>"+
                "<div class='round_box_bottom_middle'></div><div class='round_box_bottom_right'></div>"+
              "</div>" +
            "</div>", block.binding )
  end
  
  def close_overlay
    "<a href=# onclick='Element.blindUp(\"overlay\");'>#{'close'}</a>"
  end
  
end
