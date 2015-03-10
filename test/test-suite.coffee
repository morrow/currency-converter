class TestSuite

  TESTS: ['randomDataTest']
  FIELDS: ['country', 'currency', 'input','include_commission', 'rate', 'expected_amount','actual_amount',  'expected_fees',  'actual_fees', 'expected_total', 'actual_total','expected_receives','actual_receives',  'pass']

  constructor: (ele)->
    #disable conversion delay 
    window.frames[0].converter.CONFIGURATION.conversion_keypress_delay = 0
    # create first row of table results
    $('#test-results thead').append('<tr></tr>')
    # create table header
    for field in @FIELDS
      $('#test-results thead tr').append "<th>#{field.replace(/_/g, ' ')}</th>"
    # set up listeners
    @listen()
    # run tests
    @runTests()

  listen: ->
    # checkbox change
    $(window.frames[0].document).find('#converter #include-commission').on 'change', (e)=> 
      window.frames[0].converter.checkboxHandler($(window.frames[0].document).find('#converter #include-commission').is(":checked") )
    # select change
    $(window.frames[0].document).find('#converter .select select').on 'change', (e)=> 
      window.frames[0].converter.selectHandler($(e.target).parents('div').attr('id'), $(e.target).val())
    # input change
    $(window.frames[0].document).find('#converter #input').on 'keyup', 
      (e)=> window.frames[0].converter.inputHandler(e.target.value)
    # fire initial change event for each select to update them
    $(window.frames[0].document).find('#converter .select select').change()    
    # stop test execution on blur 
    $(window.frames[0]).blur =>
      window.clearInterval(window.currency_interval) 
      window.currency_interval = null
      window.clearTimeout(window.currency_timeout) 
      window.currency_timeout = null
    # resume tests on focus
    $(window.frames[0]).focus =>
      @runTests() unless window.currency_interval
    $(window.top).focus =>
      @runTests() unless window.currency_interval


  runTests: ->
    if JSON.stringify( window.frames[0].converter.rates ) == '{"AUD":1}'
      window.setTimeout( (=> @runTests() ), 100)
    else
      for test in @TESTS
        @[test]()

  # round number according to significant_digits
  roundNum:( number, significant_digits=window.frames[0].converter.CONFIGURATION.significant_digits )->
    number = parseFloat(number.toString().replace(',', ''))
    rounder = Math.pow( 10, significant_digits )
    return ( Math.round( number * rounder ) / rounder ).toFixed( significant_digits )

  # parse number from comma delimited string 
  parseNum: ( input )->
    return '' if not input or not input.toString().replace( /,|\./g, '' ).match( /[0-9]/ )
    return parseFloat( parseFloat( input.toString().replace( /,/g, '' ) ).toFixed( window.frames[0].converter.CONFIGURATION.significant_digits ) )

  getCommission: ( amount )->
    amount = @parseNum( amount )
    @commission_rate = 0.05
    @commission_rate = 0.04 if amount >= 1000
    @commission_rate = 0.03 if amount >= 3000
    @commission_rate = 0.02 if amount >= 4000
    @commission_rate = 0.02 if amount >= 5000 # negotiable
    return amount * @commission_rate

  randomDataTest: ->
    # changing currency 
    @currencies = window.frames[0].converter.CONFIGURATION.currencies_enabled_remote
    $(window.frames[0].document).find('#converter .select select').change()
    window.clearInterval(window.currency_interval) 
    window.currency_interval = window.setInterval( (=> @inputData(1) ), 100)
    window.clearTimeout(window.currency_timeout) 
    window.currency_timeout = window.setTimeout( "window.clearInterval(window.currency_interval)", 5 * 60 * 1000)

  inputData: (n)->
    # input random values
    $(window.frames[0].document).find('#include-commission').prop('checked', Math.random() > 0.6 ).change()
    $(window.frames[0].document).find('#remote-country select').val( @currencies[Math.floor(Math.random() * @currencies.length)] ).change()      
    $(window.frames[0].document).find('#currency select option').eq(~~(Math.random() * $(window.frames[0].document).find('#currency select option').length)).prop('selected', true).change()
    $(window.frames[0].document).find('#input').val( ( @roundNum( Math.random() * 10000 ) ) ).keyup()
    window.setTimeout( (=> @checkResult(n) ), 10)

  checkResult: (n)->
    @country = $(window.frames[0].document).find('#remote-country select').val()
    @currency = $(window.frames[0].document).find('#currency select option:selected').val()
    @include_commission = $(window.frames[0].document).find('#include-commission').prop('checked')
    @input = $(window.frames[0].document).find('#input').val()
    # read actual outputs
    @actual_amount = $(window.frames[0].document).find('#amount').text().replace(/,/, '')
    @actual_fees = $(window.frames[0].document).find('.fees > .amount').text().replace(/,/, '')
    @actual_total = $(window.frames[0].document).find('#total-due').text().replace(/,/, '')
    @actual_receives = $(window.frames[0].document).find('.receives .amount').text().replace(/,/, '')
    # calculate expected outputs
    @remote_currency = window.frames[0].converter.remote_currency
    @rates = window.frames[0].converter.rates
    @rate = @rates[@remote_currency]
    # converting to remote currency 
    if @currency == 'AUD'
      # input is in AUD
      @local_value = @parseNum( @input )
      @commission = @getCommission( @local_value )
      @local_value -= @commission if @include_commission
      @remote_value = @local_value / @rates[@remote_currency]
    else if @currency == @remote_currency
      # input is remote currency
      @remote_value = @input
      @commission = @getCommission( @remote_value * @rates[@remote_currency] )
      @local_value  = @remote_value * @rates[@remote_currency]
      #@local_value += @commission if @include_commission
    else
      # input is not local or remote currency (USD)
      @local_value = @input * @rates[@currency]
      @commission = @getCommission( @local_value )
      @local_value -= @commission if @include_commission
      @remote_value = @local_value / @rates[@remote_currency]
    @expected_amount = @roundNum( @local_value )
    @expected_fees = @roundNum( @commission )
    @expected_total = @roundNum( @local_value + @commission ) 
    @expected_receives = @roundNum( @remote_value )
    @pass = true
    if @expected_amount != @actual_amount
      @pass = false 
    if @expected_fees != @actual_fees
      @pass = false 
    if @expected_total != @actual_total
      @pass = false
    if @expected_receives != @actual_receives
      @pass = false 
    return window.setTimeout( (=> @checkResult(n + 1)), 10) unless @pass or n > 8
    tr = $('<tr></tr>')
    for col in @FIELDS
      value = @[col] 
      if value and value.toString().match(/\d+/) and col != 'rate' and col != 'include_commission'
        value = @roundNum( value ) 
      if col is 'pass'
        value = '✓' if @pass
        value = '✗' unless @pass
      tr.append "<td class='#{col}' title='#{col.replace(/_/g, ' ')}'>#{value}</td>"
    tr.addClass 'fail' if @pass is false
    tr.addClass 'pass' if @pass is true
    $('#test-results').append( tr ) if @input