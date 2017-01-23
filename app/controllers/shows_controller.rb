class ShowsController < ApplicationController

    def view
        if params[:view] == 'all'
            view_all
            return
        end
        if params[:id]
            @show = Show.find_by(id: params[:id])
            if @show
                set_title(:before => @show.get_title)
                render 'view'
            elsif !@show.is_published?
                flash[:warning] = "This show is not available yet. Please try again later."
                redirect_to '/'
            else
                flash[:danger] = "This show was not found. Please try again."
                redirect_to '/'
            end
            return
        end
        title = params[:title]
        show_number = params[:showNumber]
        if show_number.nil?
            show_number = params[:show_number]
        end
        if title.nil? or show_number.nil?
            @shows = Show.all.sort_by(&:get_title)
            @split_shows = Utils.split_array(Show, sort_by: 2)
            set_title(:before => "Shows")
            render 'view_all'; return
        end
        Show.all.each do |show|
            if show.title = title and show.show_number.to_s == show_number
                @show = show; break
            end
        end
        if @show.nil?
            flash[:danger] = "Sorry, no show using the given parameters was not found. Please try again."
            redirect_to '/'; return
        end
        p @show
    end

    def view_all
        @shows = Show.all
    end

    def history
        episodes = current_user.get_episodes_watched
        if episodes.empty?
          flash[:warning] = "Sorry, we don't know which epsiodes you've watched yet."
          redirect_to '/'
          return
        end
        @episodes = episodes.map{|e| Episode.find(e)}
        @episodes.select!{|e| e.is_published?}
        @episodes.reverse!
    end

end
