# frozen_string_literal: true

require_relative 'test_helper'

# The asset layer: parsing the agent table and cutting frames out of the sheet.
class TestAgent < Minitest::Test
  include AgentFixtures

  def test_loads_the_vendored_clippy
    real_agent.then do |agent|
      assert_equal([124, 93], agent.frame_size)
      assert_equal(43, agent.animation_names.size)
      assert_includes(agent.animation_names, 'Greeting')
    end
  end

  def test_animation_names_are_sorted
    real_agent.animation_names.then do |names|
      assert_equal(names.sort, names)
    end
  end

  def test_frames_returns_nil_for_an_unknown_animation
    assert_nil(real_agent.frames('NoSuchAnimation'))
    refute(real_agent.animation?('NoSuchAnimation'))
  end

  def test_every_frame_offset_lands_on_the_sheet
    real_agent.then do |agent|
      offsets = agent.animation_names
                     .flat_map { |name| agent.frames(name) }
                     .flat_map { |frame| frame['images'].to_a }
                     .uniq

      assert_equal(902, offsets.size)
      assert_empty(offsets.reject { |offset| agent.texture_at(offset) })
    end
  end

  def test_textures_are_cached_by_offset
    real_agent.then do |agent|
      assert_same(agent.texture_at([124, 0]), agent.texture_at([124, 0]))
    end
  end

  def test_offsets_outside_the_sheet_yield_nil_rather_than_raising
    real_agent.then do |agent|
      assert_nil(agent.texture_at([99_999, 0]))
      assert_nil(agent.texture_at([-124, 0]))
    end
  end

  def test_scale_multiplies_the_frame_without_smoothing
    assert_equal(124, real_agent.texture_at([0, 0]).width)
    assert_equal(248, real_agent(scale: 2).texture_at([0, 0]).width)
    assert_equal(372, real_agent(scale: 3).display_width)
  end

  def test_a_missing_agent_directory_fails_loudly
    Clippy::Agent.new(root: File.join(tmpdir, 'nowhere')).then do |agent|
      assert_raises(Clippy::Agent::LoadError) { agent.data }
    end
  end

  def test_a_table_without_animations_fails_loudly
    fixture_agent({ 'framesize' => [4, 4] }).then do |agent|
      assert_raises(Clippy::Agent::LoadError) { agent.animation_names }
    end
  end

  def test_a_missing_sheet_fails_loudly
    fixture_agent({ 'framesize' => [4, 4], 'animations' => {} }).then do |agent|
      File.delete(File.join(tmpdir, 'map.png'))
      assert_raises(Clippy::Agent::LoadError) { agent.sheet }
    end
  end
end
