#-------------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-------------------------------------------------------------------------------
#
# NOTE!
#
# Untested under OSX. OSX have multiple models per process which this plugin
# has not been designed or tested against.
#
#-------------------------------------------------------------------------------

require 'sketchup.rb'

#-------------------------------------------------------------------------------


# <hotfix>
# Need to ensure the parent namespaces exists. Normally TT_Lib2 defines this.
module TT;end
module TT::Plugins;end
# </hotfix>
module TT::Plugins::SelectionMemory
  
  
  ### CONSTANTS ### ------------------------------------------------------------
  
  # Plugin information
  PLUGIN_ID       = 'TT_SelectionMemory'.freeze
  PLUGIN_NAME     = 'Selection Memory'.freeze
  PLUGIN_VERSION  = '1.0.1'.freeze
  
  # Modify this constant to adjust the selection size to suit your needs.
  SELECTION_STACK_SIZE = 5
  
  ### VARIABLES ### ------------------------------------------------------------
  
  @selection = Array.new( SELECTION_STACK_SIZE, [] )
  @index = 0
  @restoring = false
  
  
  ### MENU & TOOLBARS ### ------------------------------------------------------
  
  unless file_loaded?( __FILE__ )
    # Menus
    menu = UI.menu( 'Edit' )
    menu.add_item( 'Cycle Previous Selections' ) { self.cycle_selections }
  end 
  
  
  ### LIB FREDO UPDATER ### ----------------------------------------------------
  
  def self.register_plugin_for_LibFredo6
    {   
      :name => PLUGIN_NAME,
      :author => 'thomthom',
      :version => PLUGIN_VERSION.to_s,
      :date => '09 Jan 12',
      :description => 'Cycles through previous selections.',
      :link_info => 'http://forums.sketchucation.com/viewtopic.php?f=323&t=42469'
    }
  end
  
  
  ### MAIN SCRIPT ### ----------------------------------------------------------

  
  # @since 1.0.0
  def self.cycle_selections
    @index = ( @index + 1 ) % @selection.size
    valid_selection = @selection[@index].select { |e| e.valid? }
    @restoring = true
    Sketchup.active_model.selection.clear
    Sketchup.active_model.selection.add( valid_selection )
    @restoring = false
  end
  
  
  # @since 1.0.0
  def self.cache_selection( selection )
    unless @restoring
      @selection.unshift( selection.to_a )
      @selection.pop
      @index = 0
    end
  end
  
  # @since 1.0.0
  def self.clear_selection( selection )
    unless @restoring
      @index = SELECTION_STACK_SIZE - 1
    end
  end
  
  
  # @since 1.0.0
  def self.reset
    @selection = Array.new( SELECTION_STACK_SIZE, [] )
    @index = 0
    @restoring = false
  end
  
  
  # @since 1.0.0
  class SelectionMemoryObserver < Sketchup::SelectionObserver
    
    # @since 1.0.0
    def onSelectionBulkChange( selection )
      TT::Plugins::SelectionMemory.cache_selection( selection )
    end
    
    def onSelectionCleared( selection )
      TT::Plugins::SelectionMemory.clear_selection( selection )
    end
    
  end
  
  
  # @since 1.0.0
  class SelectionMemoryAppObserver < Sketchup::AppObserver
  
    # @since 1.0.0
    def onNewModel( model )
      observe_selection( model )
    end
    
    # @since 1.0.0
    def onOpenModel( model )
      observe_selection( model )
    end
    
    private
    
    # @since 1.0.0
    def observe_selection( model )
      model.selection.add_observer( SelectionMemoryObserver.new )
      TT::Plugins::SelectionMemory.reset
    end
    
  end
  
  
  # @since 1.0.0
  unless file_loaded?( __FILE__ )
    Sketchup.add_observer( SelectionMemoryAppObserver.new )
    Sketchup.active_model.selection.add_observer( SelectionMemoryObserver.new )
  end


  
  ### DEBUG ### ----------------------------------------------------------------
  
  # @note Debug method to reload the plugin.
  #
  # @example
  #   TT::Plugins::SelectionMemory.reload
  #
  # @since 1.0.0
  def self.reload( tt_lib = false )
    original_verbose = $VERBOSE
    $VERBOSE = nil
    load __FILE__
  ensure
    $VERBOSE = original_verbose
  end

end # module

#-------------------------------------------------------------------------------

file_loaded( __FILE__ )

#-------------------------------------------------------------------------------