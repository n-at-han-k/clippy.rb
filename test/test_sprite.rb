# frozen_string_literal: true

require_relative 'test_helper'

# The frame-succession rules. This is the part of the agent format that is easy
# to get wrong and invisible when you do: a mishandled branch just makes an
# idle animation feel stiff, and a mishandled exitBranch makes Clippy ignore
# being dismissed.
class TestSprite < Minitest::Test
  include AgentFixtures

  def sprite = @sprite ||= Clippy::Sprite.new(agent: real_agent)

  # `next_index` is the whole rule set, so it is worth driving directly rather
  # than inferring it from timings.
  def next_index(frame, index: 0, exiting: false)
    sprite.tap do |s|
      s.instance_variable_set(:@index, index)
      s.instance_variable_set(:@exiting, exiting)
    end.send(:next_index, frame)
  end

  def test_a_plain_frame_advances_by_one
    assert_equal(6, next_index({ 'duration' => 10 }, index: 5))
  end

  def test_branching_jumps_to_the_branch
    { 'branching' => { 'branches' => [{ 'frameIndex' => 30, 'weight' => 100 }] } }
      .then { |frame| assert_equal(30, next_index(frame, index: 0)) }
  end

  def test_a_branch_that_does_not_fire_falls_through_to_the_next_frame
    # Weight 0 can never be rolled, so this must not jump.
    { 'branching' => { 'branches' => [{ 'frameIndex' => 30, 'weight' => 0 }] } }
      .then { |frame| assert_equal(4, next_index(frame, index: 3)) }
  end

  def test_branch_weights_are_respected_over_many_rolls
    frame = { 'branching' => { 'branches' => [{ 'frameIndex' => 30, 'weight' => 40 }] } }
    taken = 2_000.times.count { next_index(frame, index: 0) == 30 }

    # 40% of 2000 is 800; a generous band keeps this from flaking.
    assert_includes(700..900, taken, "expected ~800 branch hits, got #{taken}")
  end

  def test_exiting_takes_the_exit_branch_in_preference_to_branching
    frame = {
      'exitBranch' => 7,
      'branching'  => { 'branches' => [{ 'frameIndex' => 30, 'weight' => 100 }] },
    }

    assert_equal(30, next_index(frame, index: 0, exiting: false))
    assert_equal(7, next_index(frame, index: 0, exiting: true))
  end

  def test_exiting_a_frame_with_no_exit_branch_just_advances
    assert_equal(3, next_index({ 'duration' => 10 }, index: 2, exiting: true))
  end

  # The real reason exitBranch matters: without it, asking a weighted loop to
  # stop would never be honoured.
  def test_every_looping_animation_offers_a_way_out
    real_agent.then do |agent|
      looping = agent.animation_names.select do |name|
        agent.frames(name).any? { |frame| frame['branching'] }
      end

      refute_empty(looping)

      without_exit = looping.reject do |name|
        agent.frames(name).any? { |frame| frame['exitBranch'] }
      end

      assert_empty(without_exit, "these loop with no exitBranch: #{without_exit.inspect}")
    end
  end

  def test_playing_an_unknown_animation_is_a_no_op
    sprite.build
    sprite.picture.paintable.then do |before|
      sprite.play('NoSuchAnimation')

      assert_same(before, sprite.picture.paintable)
    end
  end

  def test_rest_pose_is_a_single_frame
    assert_equal(1, real_agent.frames(Clippy::Sprite::REST_ANIMATION).size)
  end

  def test_build_shows_a_frame_immediately
    sprite.build

    refute_nil(sprite.picture.paintable)
    refute_predicate(sprite, :playing?)
  end
end
