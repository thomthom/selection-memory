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


module TT::Plugins::SelectionMemory


  ### CONSTANTS ### ------------------------------------------------------------

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
  #   TT::Plugins::Template.reload
  #
  # @param [Boolean] tt_lib Reloads TT_Lib2 if +true+.
  #
  # @return [Integer] Number of files reloaded.
  # @since 1.0.0
  def self.reload( tt_lib = false )
    original_verbose = $VERBOSE
    $VERBOSE = nil
    TT::Lib.reload if tt_lib
    # Core file (this)
    load __FILE__
    # Supporting files
    if defined?( PATH ) && File.exist?( PATH )
      x = Dir.glob( File.join(PATH, '*.{rb,rbs}') ).each { |file|
        load file
      }
      x.length + 1
    else
      1
    end
  ensure
    $VERBOSE = original_verbose
  end

end # module

#-------------------------------------------------------------------------------

file_loaded( __FILE__ )

#-------------------------------------------------------------------------------