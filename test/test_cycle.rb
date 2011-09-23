if RUBY_VERSION < "1.9.0"
  require 'require_relative'
end

# Get the base directory of the WFM installation
if File.symlink?(__FILE__)
  __WFMDIR__=File.dirname(File.dirname(File.expand_path(File.readlink(__FILE__),File.dirname(__FILE__))))
else
  __WFMDIR__=File.dirname(File.expand_path(File.dirname(__FILE__)))
end

# Add include paths for WFM and libxml-ruby libraries
$:.unshift("#{__WFMDIR__}/lib")
$:.unshift("#{__WFMDIR__}/libxml-ruby/lib")
$:.unshift("#{__WFMDIR__}/libxml-ruby/ext/libxml")
$:.unshift("#{__WFMDIR__}/sqlite3-ruby/lib")
$:.unshift("#{__WFMDIR__}/sqlite3-ruby/ext")


require 'test/unit'
require 'fileutils'
require_relative '../lib/workflowmgr/cycle'

class TestCycle < Test::Unit::TestCase

  def test_cyclecron_init

    # Test asterisk forms
    cycle1=WorkflowMgr::CycleCron.new("test",["*","*","*","*","*","*"])
    cycle1=WorkflowMgr::CycleCron.new("test",["*/2","*","*","*","*","*"])

    # Test each non-asterisk form
    cycle1=WorkflowMgr::CycleCron.new("test",["0","*","*","*","*","*"])
    cycle1=WorkflowMgr::CycleCron.new("test",["0-10","*","*","*","*","*"])
    cycle1=WorkflowMgr::CycleCron.new("test",["0-10/2","*","*","*","*","*"])

    # Test lists for each form that can follow a single integer form
    cycle1=WorkflowMgr::CycleCron.new("test",["0,1","*","*","*","*","*"])
    cycle1=WorkflowMgr::CycleCron.new("test",["0,1-10","*","*","*","*","*"])
    cycle1=WorkflowMgr::CycleCron.new("test",["0,1-10/2","*","*","*","*","*"])

    # Test lists for each form that can follow a range form
    cycle1=WorkflowMgr::CycleCron.new("test",["0-10,11","*","*","*","*","*"])
    cycle1=WorkflowMgr::CycleCron.new("test",["0-10,11-20","*","*","*","*","*"])
    cycle1=WorkflowMgr::CycleCron.new("test",["0-10,11-20/2","*","*","*","*","*"])

    # Test lists for each form that can follow a stepped range form
    cycle1=WorkflowMgr::CycleCron.new("test",["0-10/2,11","*","*","*","*","*"])
    cycle1=WorkflowMgr::CycleCron.new("test",["0-10/2,11-20","*","*","*","*","*"])
    cycle1=WorkflowMgr::CycleCron.new("test",["0-10/2,11-20/2","*","*","*","*","*"])

  end

  def test_cyclecron_first

    cycle1=WorkflowMgr::CycleCron.new("test",["*","*","*","*","*","*"])
    assert_equal(Time.gm(1900,1,1,0,0),cycle1.first)
    cycle1=WorkflowMgr::CycleCron.new("test",["0","*/6","*","*","2008-2012","*"])
    assert_equal(Time.gm(2008,1,1,0,0),cycle1.first)
    cycle1=WorkflowMgr::CycleCron.new("test",["30","12","15-31","4,8","2010","*"])
    assert_equal(Time.gm(2010,4,15,12,30),cycle1.first)

  end

  def test_cyclecron_next

    cycle1=WorkflowMgr::CycleCron.new("test",["*","*","*","*","*","*"])
    reftime=Time.at(Time.now.to_i)
    reftime -= reftime.sec
    nextcycle=cycle1.next(reftime)
    assert_equal(reftime,nextcycle)

    cycle1=WorkflowMgr::CycleCron.new("test",["0","0","*","*","*","*"])
    reftime=Time.gm(2011,1,1,0,0)
    nextcycle=cycle1.next(reftime)
    assert_equal(Time.gm(2011,1,1,0,0),nextcycle)

    cycle1=WorkflowMgr::CycleCron.new("test",["0","0,12","1-15","2","*","*"])
    reftime=Time.gm(2007,3,28,15,43)
    nextcycle=cycle1.next(reftime)
    assert_equal(Time.gm(2008,2,1,0,0),nextcycle)

    cycle1=WorkflowMgr::CycleCron.new("test",["0","0,12","29-31","2","*","*"])
    reftime=Time.gm(2009,3,28,15,43)
    nextcycle=cycle1.next(reftime)
    assert_equal(Time.gm(2012,2,29,0,0),nextcycle)

    cycle1=WorkflowMgr::CycleCron.new("test",["0","0,12","3-31","2","*","1"])
    reftime=Time.gm(2009,2,28,15,43)
    nextcycle=cycle1.next(reftime)
    assert_equal(Time.gm(2010,2,1,0,0),nextcycle)

    cycle1=WorkflowMgr::CycleCron.new("test",["0","0,12","3-31","2","*","6"])
    reftime=Time.gm(2009,2,28,15,43)
    nextcycle=cycle1.next(reftime)
    assert_equal(Time.gm(2010,2,3,0,0),nextcycle)

    cycle1=WorkflowMgr::CycleCron.new("test",["0","0,12","*","*","*","*"])
    reftime=Time.gm(2009,2,28,15,43)
    nextcycle=cycle1.next(reftime)
    assert_equal(Time.gm(2009,3,1,0,0),nextcycle)

  end

  def test_cyclecron_previous

    cycle1=WorkflowMgr::CycleCron.new("test",["*","*","*","*","*","*"])
    reftime=Time.at(Time.now.to_i)
    reftime -= reftime.sec
    nextcycle=cycle1.previous(reftime)
    assert_equal(reftime,nextcycle)

    cycle1=WorkflowMgr::CycleCron.new("test",["0","0","*","*","*","*"])
    reftime=Time.gm(2011,1,1,0,0)
    nextcycle=cycle1.previous(reftime)
    assert_equal(Time.gm(2011,1,1,0,0),nextcycle)

    cycle1=WorkflowMgr::CycleCron.new("test",["0","12","*","*","*","*"])
    reftime=Time.gm(2011,3,1,0,0)
    nextcycle=cycle1.previous(reftime)
    assert_equal(Time.gm(2011,2,28,12,0),nextcycle)

  end

  def test_cyclecron_member

    cycle1=WorkflowMgr::CycleCron.new("test",["*","*","*","*","*","*"])
    assert_equal(true,cycle1.member?(Time.now))

    cycle1=WorkflowMgr::CycleCron.new("test",["*","*","*","*","1970","*"])
    assert_equal(false,cycle1.member?(Time.now))

    cycle1=WorkflowMgr::CycleCron.new("test",["*","*","*","*","2011","2-5"])
    assert_equal(true,cycle1.member?(Time.gm(2011,8,30)))

    cycle1=WorkflowMgr::CycleCron.new("test",["*","*","*","*","2011","2-5"])
    assert_equal(false,cycle1.member?(Time.gm(2011,8,29)))

    cycle1=WorkflowMgr::CycleCron.new("test",["*","*","10-15","*","2011","2-5"])
    assert_equal(true,cycle1.member?(Time.gm(2011,8,15)))

    cycle1=WorkflowMgr::CycleCron.new("test",["*","*","10-15","*","2011","2-5"])
    assert_equal(true,cycle1.member?(Time.gm(2011,8,30)))

    cycle1=WorkflowMgr::CycleCron.new("test",["*","*","10-15","*","2011","2-5"])
    assert_equal(false,cycle1.member?(Time.gm(2011,8,1)))

  end

  def test_cycleinterval_init

    cycle1=WorkflowMgr::CycleInterval.new("test",["201101010000","201201010000","1:00:00:00"])
    cycle1=WorkflowMgr::CycleInterval.new("test",["201101010000","201201010000","1:00:00"])
    cycle1=WorkflowMgr::CycleInterval.new("test",["201101010000","201201010000","1:00"])

  end

  def test_cycleinterval_first

    cycle1=WorkflowMgr::CycleInterval.new("test",["201101010000","201201010000","1:00:00:00"])
    assert_equal(Time.gm(2011,1,1,0),cycle1.first)
    cycle1=WorkflowMgr::CycleInterval.new("test",["201101010000","201201010000","1:00:00"])
    assert_equal(Time.gm(2011,1,1,0),cycle1.first)
    cycle1=WorkflowMgr::CycleInterval.new("test",["201101010000","201201010000","1:00"])
    assert_equal(Time.gm(2011,1,1,0),cycle1.first)

  end

  def test_cycleinterval_next

    cycle1=WorkflowMgr::CycleInterval.new("test",["201101010000","201201010000","1:00:00:00"])

    cycle2=cycle1.next(cycle1.first)
    assert_equal(Time.gm(2011,1,1,0),cycle2)

    cycle2=cycle1.next(cycle1.first+1)
    assert_equal(Time.gm(2011,1,2,0),cycle2)

    cycle2=cycle1.next(cycle1.first-1)
    assert_equal(Time.gm(2011,1,1,0),cycle2)

    cycle1=WorkflowMgr::CycleInterval.new("test",["201101010000","201201010000","1:00:00"])

    cycle2=cycle1.next(cycle1.first)
    assert_equal(Time.gm(2011,1,1,0),cycle2)

    cycle2=cycle1.next(cycle1.first+1)
    assert_equal(Time.gm(2011,1,1,1),cycle2)

    cycle2=cycle1.next(cycle1.first-1)
    assert_equal(Time.gm(2011,1,1,0),cycle2)

    cycle1=WorkflowMgr::CycleInterval.new("test",["201101010000","201201010000","1:00"])

    cycle2=cycle1.next(cycle1.first)
    assert_equal(Time.gm(2011,1,1,0,0),cycle2)

    cycle2=cycle1.next(cycle1.first+1)
    assert_equal(Time.gm(2011,1,1,0,1),cycle2)

    cycle2=cycle1.next(cycle1.first-1)
    assert_equal(Time.gm(2011,1,1,0,0),cycle2)

  end


  def test_cycleinterval_previous

    cycle1=WorkflowMgr::CycleInterval.new("test",["201101010000","201201010000","1:00:00:00"])

    cycle2=cycle1.previous(Time.gm(2011,3,1,0,0,0))
    assert_equal(Time.gm(2011,3,1,0),cycle2)

    cycle2=cycle1.previous(Time.gm(2011,3,1,0,0,0)+1)
    assert_equal(Time.gm(2011,3,1,0),cycle2)

    cycle2=cycle1.previous(Time.gm(2011,3,1,0,0,0)-1)
    assert_equal(Time.gm(2011,2,28,0),cycle2)

    cycle1=WorkflowMgr::CycleInterval.new("test",["201101010000","201201010000","1:00:00"])

    cycle2=cycle1.previous(Time.gm(2011,3,1,0,0,0))
    assert_equal(Time.gm(2011,3,1,0),cycle2)

    cycle2=cycle1.previous(Time.gm(2011,3,1,0,0,0)+1)
    assert_equal(Time.gm(2011,3,1,0),cycle2)

    cycle2=cycle1.previous(Time.gm(2011,3,1,0,0,0)-1)
    assert_equal(Time.gm(2011,2,28,23),cycle2)

    cycle1=WorkflowMgr::CycleInterval.new("test",["201101010000","201201010000","1:00"])

    cycle2=cycle1.previous(Time.gm(2011,3,1,0,0,0))
    assert_equal(Time.gm(2011,3,1,0,0),cycle2)

    cycle2=cycle1.previous(Time.gm(2011,3,1,0,0,0)+1)
    assert_equal(Time.gm(2011,3,1,0,0),cycle2)

    cycle2=cycle1.previous(Time.gm(2011,3,1,0,0,0)-1)
    assert_equal(Time.gm(2011,2,28,23,59),cycle2)

  end


  def test_cycleinterval_member

    cycle1=WorkflowMgr::CycleInterval.new("test",["201101010000","201201010000","1:00:00:00"])
    assert_equal(false,cycle1.member?(Time.gm(1970,1,1)))

    cycle1=WorkflowMgr::CycleInterval.new("test",["201101010000","201201010000","1:00:00:00"])
    assert_equal(false,cycle1.member?(Time.gm(2100,1,1)))

    cycle1=WorkflowMgr::CycleInterval.new("test",["201101010000","201201010000","1:00:00:00"])
    assert_equal(true,cycle1.member?(Time.gm(2011,8,1)))

    cycle1=WorkflowMgr::CycleInterval.new("test",["201101010000","201201010000","2:00:00:00"])
    assert_equal(false,cycle1.member?(Time.gm(2011,1,2)))

    cycle1=WorkflowMgr::CycleInterval.new("test",["201101010000","201201010000","2:00:00:00"])
    assert_equal(true,cycle1.member?(Time.gm(2011,1,3)))

  end

end