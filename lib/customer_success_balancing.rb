class CustomerSuccessBalancing
  attr_reader :success_managers, :customers, :away_success_managers, :sorted_managers, :sorted_customers, :customer_distribution

  def initialize(success_managers, customers, away_success_managers)
    @success_managers = success_managers
    @customers = customers
    @away_success_managers = away_success_managers
    validate_success_managers
    validate_customers

    # sort available managers and customers so we can distribute them efficiently
    available_managers = success_managers.reject { |m| away_success_managers.include?(m[:id]) }
    @sorted_managers = available_managers.sort_by { |m| m[:score] }
    @sorted_customers = customers.sort_by { |c| c[:score] }

    @customer_distribution = Hash.new(0)
  end

  def execute
    distribute
    success_manager_with_most_customers
  end

  private

  def distribute
    i = 0
    customers_amount = sorted_customers.size

    sorted_managers.each do |manager|
      # assign all customers that this manager can handle
      while i < customers_amount && sorted_customers[i][:score] <= manager[:score]
        customer_distribution[manager[:id]] += 1
        i += 1
      end
    end
  end

  def success_manager_with_most_customers
    max_customers_amount = 0
    max_id = 0
    tied = false

    # in one complete loop through `customer_distribution` we are able to get:
    # - the manager with most customers
    # - if there's a tie between managers with most customers
    customer_distribution.each do |manager_id, customers_amount|
      if customers_amount > max_customers_amount
        max_customers_amount = customers_amount
        max_id = manager_id
        tied = false
      elsif customers_amount == max_customers_amount
        tied = true
      end
    end

    return 0 if tied

    max_id
  end

  #############################################################################
  # validations
  #############################################################################

  MAX_CUSTOMERS = 1_000_000
  MAX_CUSTOMER_SIZE = 100_000
  MAX_SUCCESS_MANAGERS = 1_000
  MAX_SUCCESS_MANAGER_LEVEL = 10_000

  def validate_success_managers
    managers_amount = success_managers.size

    # 0 < managers_amount < 1,000
    unless (1..MAX_SUCCESS_MANAGERS).cover?(managers_amount)
      raise ArgumentError, 'Invalid amount of CSs: must be between 1 and 999'
    end

    # absence_amount <= managers_amount / 2
    if away_success_managers.size > managers_amount / 2
      raise ArgumentError, 'Too many Customer Success absence'
    end

    seen_scores = Set.new
    success_managers.each do |cs|
      level = cs[:score]

      # all managers have different levels
      raise ArgumentError, 'Duplicate CS levels are not allowed' if seen_scores.include?(level)

      # 0 < manager_level < 10,000
      raise ArgumentError, 'CS level must be between 1 and 9,999' unless (1...MAX_SUCCESS_MANAGER_LEVEL).cover?(level)

      # 0 < manager_id < 1,000
      raise ArgumentError, 'CS ID must be between 1 and 999' unless (1...MAX_SUCCESS_MANAGERS).cover?(cs[:id])

      seen_scores.add(level)
    end
  end

  def validate_customers
    # 0 < customers_amount < 1,000,000
    unless (1...1_000_000).cover?(customers.size)
      raise ArgumentError, 'Invalid number of customers: must be between 1 and 1,000,000'
    end

    customers.each do |customer|

      # 0 < customer_id < 1,000,000
      raise ArgumentError, 'customer ID must be between 1 and 999,999' unless (1...MAX_CUSTOMERS).cover?(customer[:id])

      # 0 < customer_size < 100,000
      raise ArgumentError, 'customer size must be between 1 and 999' unless (1...MAX_CUSTOMER_SIZE).cover?(customer[:score])
    end
  end
end
