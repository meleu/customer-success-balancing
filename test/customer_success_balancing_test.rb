require 'minitest/autorun'
require 'timeout'

require_relative '../lib/customer_success_balancing'

class CustomerSuccessBalancingTests < Minitest::Test
  ##############################################################################
  # Tests based on the requirements
  ##############################################################################
  # n = amount of CSs
  # 0 < n < 1,000
  ##############################################################################
  def test_raises_error_when_no_CS_is_given
    assert_raises ArgumentError do
      CustomerSuccessBalancing.new(
        [],
        build_scores([10, 20]),
        []
      )
    end
  end

  def test_raises_error_when_CS_amount_exceeds_999
    assert_raises ArgumentError do
      CustomerSuccessBalancing.new(
        build_scores(Array.new(1000) { 50 }),
        build_scores([10, 20]),
        []
      )
    end
  end

  # m = amount of customers
  # 0 < m < 1,000
  ##############################################################################
  def test_raises_error_when_no_customers_are_given
    assert_raises ArgumentError do
      CustomerSuccessBalancing.new(
        build_scores([50]),
        [],
        []
      )
    end
  end

  def test_raises_error_when_customers_amount_exceeds_a_thousand
    assert_raises ArgumentError do
      CustomerSuccessBalancing.new(
        build_scores([50]),
        build_scores(Array.new(1_000_000) { 10 }),
        []
      )
    end
  end

  # t = amount of absent CSs
  # t <= n / 2 (round to the floor)
  ##############################################################################
  def test_raises_error_when_exceeding_CS_absence_limit
    four_managers = build_scores([50, 60, 70, 80])
    three_unavailable_managers = [1, 2, 3]

    assert_raises ArgumentError do
      CustomerSuccessBalancing.new(
        four_managers,
        build_scores([10, 20]),
        three_unavailable_managers
      )
    end
  end

  def test_raises_error_when_the_only_CS_is_absent
    assert_raises ArgumentError do
      CustomerSuccessBalancing.new(
        build_scores([50]),
        build_scores([10]),
        [1]
      )
    end
  end

  # all CSs have different levels
  ##############################################################################
  def test_raises_error_when_duplicate_CS_levels
    some_managers_with_duplicate_levels = build_scores([50, 60, 50])

    assert_raises ArgumentError do
      CustomerSuccessBalancing.new(
        some_managers_with_duplicate_levels,
        build_scores([10, 20]),
        []
      )
    end
  end

  # 0 < CS level < 10,000
  ##############################################################################
  def test_raises_error_when_CS_level_is_zero
    assert_raises ArgumentError do
      CustomerSuccessBalancing.new(
        build_scores([0, 50, 100]),
        build_scores([10, 20]),
        []
      )
    end
  end

  def test_raises_error_when_CS_level_is_ten_thousand
    assert_raises ArgumentError do
      CustomerSuccessBalancing.new(
        build_scores([10_000, 100, 50]),
        build_scores([10, 20]),
        []
      )
    end
  end

  # 0 < CS.id < 1,000
  ##############################################################################
  def test_raises_error_when_CS_id_is_invalid
    manager_with_id_zero = { id: 0, score: 50 }
    assert_raises ArgumentError do
      CustomerSuccessBalancing.new(
        [manager_with_id_zero],
        build_scores([10, 20]),
        []
      )
    end

    manager_with_id_one_thousand = { id: 1_000, score: 50 }
    assert_raises ArgumentError do
      CustomerSuccessBalancing.new(
        [manager_with_id_one_thousand],
        build_scores([10, 20]),
        []
      )
    end
  end

  # 0 < customer ID < 1,000
  ##############################################################################
  def test_raises_error_when_customer_id_is_invalid
    customer_with_id_zero = { id: 0, score: 10 }
    assert_raises ArgumentError do
      CustomerSuccessBalancing.new(
        build_scores([50]),
        [customer_with_id_zero],
        []
      )
    end

    customer_with_id_too_large = { id: 1_000_000, score: 10 }
    assert_raises ArgumentError do
      CustomerSuccessBalancing.new(
        build_scores([50]),
        [customer_with_id_too_large],
        []
      )
    end
  end

  # 0 < customer size < 100,000
  ##############################################################################
  def test_raises_error_when_customer_size_is_invalid
    customer_with_zero_size = { id: 1, score: 0 }
    assert_raises ArgumentError do
      CustomerSuccessBalancing.new(
        build_scores([50]),
        [customer_with_zero_size],
        []
      )
    end

    customer_with_too_large_size = { id: 1, score: 100_000 }
    assert_raises ArgumentError do
      CustomerSuccessBalancing.new(
        build_scores([50]),
        [customer_with_too_large_size],
        []
      )
    end
  end

  ##############################################################################
  # checking performance
  ##############################################################################
  def test_large_dataset_performance
    # generate 999 managers with unique scores
    success_manager_scores = (1..9999).to_a.sample(999)
    success_managers = build_scores(success_manager_scores)

    # create 999,999 customers
    customers = build_scores(Array.new(999_999) { rand(1..99_999) })

    # randomly make 49.9% of CSs unavailable
    unavailable_managers = Array.new(499) { rand(1..999) }

    balancer = CustomerSuccessBalancing.new(success_managers, customers, unavailable_managers)

    result = Timeout.timeout(2.0) { balancer.execute }

    # we can't predict the exact result (random data)
    # so let's just assert that it returns an int before timeout
    assert result.is_a?(Integer), "Expected an integer result"
  end

  ##############################################################################
  # original tests
  ##############################################################################
  def test_scenario_one
    balancer = CustomerSuccessBalancing.new(
      build_scores([60, 20, 95, 75]),
      build_scores([90, 20, 70, 40, 60, 10]),
      [2, 4]
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_two
    balancer = CustomerSuccessBalancing.new(
      build_scores([11, 21, 31, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_three
    balancer = CustomerSuccessBalancing.new(
      build_scores(Array(1..999)),
      build_scores(Array.new(10_000, 998)),
      [999]
    )
    result = Timeout.timeout(1.0) { balancer.execute }
    assert_equal 998, result
  end

  def test_scenario_four
    balancer = CustomerSuccessBalancing.new(
      build_scores([1, 2, 3, 4, 5, 6]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_five
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 2, 3, 6, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_six
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [1, 3, 2]
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_seven
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [4, 5, 6]
    )
    assert_equal 3, balancer.execute
  end

  def test_scenario_eight
    balancer = CustomerSuccessBalancing.new(
      build_scores([60, 40, 95, 75]),
      build_scores([90, 70, 20, 40, 60, 10]),
      [2, 4]
    )
    assert_equal 1, balancer.execute
  end

  private

  def build_scores(scores)
    scores.map.with_index do |score, index|
      { id: index + 1, score: }
    end
  end
end
