class Converter

  CONFIGURATION:
    # time in milliseconds to wait after keypress before converting
    conversion_keypress_delay: 500
    # number of digits used when displaying conversions 
    significant_digits: 2
    # update exchange rates for each transaction - note that the rate limit for YQL is 2,000 calls per hour
    continually_update_rates: false
    # currencies available to send remotely, first is default
    currencies_enabled_remote: ['USD', 'ETB', 'EGP', 'SDG', 'KES']
    # currencies available to pay locally, first is default
    currencies_enabled_local: ['AUD']

  CURRENCY_DATA: 
    'USD': 
      'name':   'U.S. Dollar'
      'symbol': '$'
      'locale': 'en-US'
      'country': 'United States'
    'AUD': 
      'name':   'Australian Dollar'
      'symbol': '$'
      'locale': 'en-AU'
      'country': 'Australia'
    'ETB': 
      'name':   'Ethiopian Birr'
      'symbol': 'Br'
      'locale': 'am-ET'
      'country': 'Ethiopia'
    'EGP': 
      'name':   'Egyptian Pound'
      'symbol': 'E£'
      'locale': 'ar-EG'
      'country': 'Egypt'
    'SDG': 
      'name':   'Sudanese Pound'
      'symbol': 'SDG'
      'locale': 'ar-SU'
      'country': 'Sudan'
    'KES': 
      'name':   'Kenyan Shilling'
      'symbol': 'KSh'
      'locale': 'sw-KE'
      'country': 'Kenya'

  # constructor
  constructor: ->
    # get rates 
    @rates = window.converter_exchange_rates
    # include commission by default
    @include_commission = $('#converter #commission input').prop('checked')
    # get default remote currency
    @remote_currency = @CONFIGURATION.currencies_enabled_remote[0]
    # get default local currency
    @local_currency = @CONFIGURATION.currencies_enabled_local[0]
    # create dropdowns
    @populateSelectOptions()
    # listen for input changes
    @listen()

  # set up event listeners
  listen: ->
    @listening = true
    # select change
    $('#converter #include-commission').on 'change', (e)=>
      @checkboxHandler( $('#converter #include-commission').is(':checked') )
    $('#converter .select select').on 'change', (e)=>
      @selectHandler($(e.target).parents('div').attr('id'), $(e.target).val())
    # input change
    $('#converter #input').on 'input', (e)=>
      @inputHandler(e.target.value)
    # fire initial change event for each select to update them
    $('#converter .select select').change()

  # populate select options
  populateSelectOptions: ->
    # populate country options once only
    if $('#converter #remote-country select').text() == ''
      for currency in @CONFIGURATION.currencies_enabled_remote
        currency_data = @CURRENCY_DATA[currency]
        $('#converter #remote-country select').append( "<option value='#{currency}'>#{currency_data.country}</option>" )
    # populate currency select
    $('#converter #currency select').html('')
    # include local currency
    $('#converter #currency select').append( "<option value='#{@local_currency}'>#{@local_currency}</option>" )
    # include USD if USD isn't the local or remote currency 
    $('#converter #currency select').append( "<option value='USD'>USD</option>" ) if @local_currency != 'USD' and @remote_currency != 'USD'
    # incldue remote currency
    $('#converter #currency select').append( "<option value='#{@remote_currency}'>#{@remote_currency}</option>" )
    # trigger first onchange event
    $('#converter #currency select').change()

  # return comission rate for given value
  getCommission: ( amount )->
    amount = @parseNum( amount )
    @commission_rate = 0.05
    @commission_rate = 0.04 if amount >= 1000
    @commission_rate = 0.03 if amount >= 3000
    @commission_rate = 0.02 if amount >= 4000
    @commission_rate = 0.02 if amount >= 5000 # negotiable
    return amount * @commission_rate

  # convert
  convert: ->
    # parse number from text input 
    input = @parseNum( $('#converter #input').val() )
    # get currency
    currency = $('#converter #currency select').val()
    # converting *to* remote currency 
    if currency == @remote_currency
      # disable toggling of commission as commission is always included if input is in remote currency 
      # use-case: User wants to send X [remote currency], display how much [local currency] do they pay.
      @include_commission = true
      $('#converter #commission input').prop('checked', 'checked')
      $('#converter #commission, #commission input').attr('disabled', 'disabled')
      $('#converter #commission').addClass('disabled')
      $('#converter #commission').attr('title', 'Commission is always included for this transaction type')
    else 
      # allow toggling of commission if input is not in remote currency
      $('#converter #commission').removeClass('disabled')
      $('#converter #commission, #commission input').removeAttr('disabled')
      $('#converter #commission').removeAttr('title')
    if currency == 'AUD'
      # input is in AUD
      local_value = input
      commission = @getCommission( local_value )
      local_value -= commission if @include_commission
      remote_value = local_value / @rates[@remote_currency]
    else if currency == @remote_currency
      # input is remote currency
      remote_value = input
      commission = @getCommission( remote_value * @rates[@remote_currency] )
      local_value  = remote_value * @rates[@remote_currency]
      #local_value += commission if @include_commission
    else
      # input is not local or remote currency (USD)
      local_value = input * @rates[currency]
      commission = @getCommission( local_value )
      local_value -= commission if @include_commission
      remote_value = local_value / @rates[@remote_currency]
    # update results - total amount
    $('#converter #amount').text( @format( local_value, @local_currency ) )
    $('#converter #amount').attr( 'data-currency', @local_currency )
    $('#converter #amount').attr( 'data-amount', local_value )
    # update results - fees
    $('#converter #fees').text( @format( commission, @local_currency ) )
    $('#converter #fees').attr( 'data-currency', @local_currency )
    $('#converter #fees').attr( 'data-amount', commission )
    # update results - total due
    $('#converter #total-due').text( @format( local_value + commission, @local_currency ) )
    $('#converter #total-due').attr( 'data-currency', @local_currency )
    $('#converter #total-due').attr( 'data-amount', local_value + commission )
    $('#converter #recipient-receives').text( @format( remote_value ), @remote_currency )
    # currency info - local currency
    $('#converter .local-currency').text( @local_currency )
    $('#converter .local-currency-flag').attr 'src', "./flags/png/#{@local_currency}.png"
    $('#converter .local-currency-symbol').text( @CURRENCY_DATA[@local_currency].symbol )
    # currency info - remote currency
    $('#converter .remote-currency').text( @remote_currency )
    $('#converter .remote-currency-flag').attr 'src', "./flags/png/#{@remote_currency}.png"
    $('#converter .remote-currency-symbol').text @CURRENCY_DATA[@remote_currency].symbol
    $('#converter .conversion-rate').text( @format( 1 / @rates[@remote_currency], @remote_currency, 4) )
    # convert USD rates
    $('#converter .us-rate').each (i, ele) =>
      amount = @parseNum( $(ele).siblings('.amount').attr('data-amount') )
      currency = $(ele).siblings('.amount').data('currency')
      $(ele).find('.amount').text( @format( amount / @rates['USD'] ), 'USD' )
    # show USD rates if enabled
    if @include_us_rates
      $('#converter .us-rate').show() 
    else
      $('#converter .us-rate').hide() 
    # always show US rate for fees and amount to send
    $('#converter dd.fees .us-rate, dd.amount-to-send .us-rate').show()
    if $('#converter #input').val() == ''
      $('#converter #result').removeClass( 'expanded' )
      $('#converter #info').hide()
    else 
      $('#converter #result').addClass( 'expanded' )
      $('#converter #info').show()

  # select handler
  selectHandler:(select_id, value)->
    switch select_id
      # remote country select
      when 'remote-country'
        # change remote country flag
        $('#converter #remote-country-flag').attr('src', "./flags/png/#{value}.png")
        # change span text
        span_text = @CURRENCY_DATA[value]['country']
        $('#converter #currency select').val(value)
        # update currency select
        @selectHandler('currency', value)
        # populate select options
        @populateSelectOptions()
      # currency select
      when 'currency'
        # default to not include US rates in currency dropdown
        @include_us_rates = false
        # set remote currency, converting FROM AUD
        if value == 'AUD'
          @remote_currency = $('#converter #remote-country select').val()
        # converting TO USD
        else if value == 'USD' and $('#converter #remote-country select').val() != 'USD'
          @include_us_rates = true
        # set remote currency - converting TO given currency
        else
          @remote_currency = value
        # update span text
        span_text = value
        # convert currencies
        @convert()
    # update span element associated with select (actual select is hidden for styling purposes)
    $("#converter ##{select_id} select").siblings('span').text( span_text)

  # check box handler
  checkboxHandler: (bool)=>
    @include_commission = bool
    @convert()

  # input handler
  inputHandler: (value)->
    # show results after a delay, unless input is blank
    if value == ''
      delay = 0
    else
      delay = @CONFIGURATION.conversion_keypress_delay
    window.clearTimeout(window.keypress_timeout)
    # update rates if configured to do so
    if @CONFIGURATION.continually_update_rates
      window.keypress_timeout = window.setTimeout((=> @updateExchangeRates( => @convert() ) ), delay)
    # otherwise convert after keypress delay
    else
      window.keypress_timeout = window.setTimeout((=> @convert() ), delay)

  # format number
  format: ( number, currency='USD', significant_digits=@CONFIGURATION.significant_digits )->
    return '' if not not not number.toString().match /[0-9]/
    # round number
    number = @roundNum( number, significant_digits )
    # comma delimit number
    parts = number.toString().split( '.' )
    parts[0] = parts[0].replace( /\B(?=(\d{3})+(?!\d))/g, ',' )
    return parts.join '.'

  # parse number from comma delimited string 
  parseNum: ( input )->
    return '' if not input or not input.toString().replace( /,|\./g, '' ).match( /[0-9]/ )
    return parseFloat( parseFloat( input.toString().replace( /,/g, '' ) ).toFixed( @CONFIGURATION.significant_digits ) )

  # round number according to significant_digits
  roundNum:( number, significant_digits=@CONFIGURATION.significant_digits )->
    return '' if not number.toString().match /[0-9]/
    rounder = Math.pow( 10, significant_digits )
    return ( Math.round( number * rounder ) / rounder ).toFixed( significant_digits )