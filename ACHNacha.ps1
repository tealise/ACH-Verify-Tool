# NACHA FIELD DEFINITIONS
# NUMERIC FIELD is 0-9, prepended with 0s
# NUMERIC_RIGHT FIELD is 0-9 prepended with spaces
# ALPHANUMERIC FIELD is 0-9 A-z postpended with spaces

Function Format-Numeric {
    param($line,[int]$length)
    $string_length = ([string]$line).Length
    ('0' * ($length - $string_length)) + $line
}

Function Format-NumericDollar {
    param($line,[int]$length)
    $line_cents = [string](([int]$line) * 100)
    $string_length = $line_cents.Length
    ('0' * ($length - $string_length)) + $line_cents
}

Function Format-NumericRight {
    param($line,[int]$length)
    $string_length = ([string]$line).Length
    (' ' * ($length - $string_length)) + $line
}

Function Format-AlphaNumeric {
    param($line,[int]$length)
    $string_length = ([string]$line).Length
    $line + (' ' * ($length - $string_length))
}

Function Format-Blank {
    param($line,[int]$length)
    $string_length = 0
    (' ' * ($length - $string_length))
}

$nacha_field_definitions = [PSCustomObject]@{
    'record_type' = [PSCustomObject]@{
        'length' = 1
        'type'   = 'numeric'
    }
    
    # 1 - FILE HEADER RECORD FIELDS
    'priority_code' = [PSCustomObject]@{
        'length' = 2
        'type'   = 'numeric'
    }
    'immediate_destination' = [PSCustomObject]@{
        'length' = 10
        'type'   = 'numeric_right'
    }
    'immediate_origin' = [PSCustomObject]@{
        'length' = 10
        'type'   = 'numeric_right'
    }
    'file_creation_date' = [PSCustomObject]@{
        'length' = 6
        'type'   = 'numeric'
    }
    'file_creation_time' = [PSCustomObject]@{
        'length' = 4
        'type'   = 'numeric'
    }
    'file_id_modifier' = [PSCustomObject]@{
        'length' = 1
        'type'   = 'alphanumeric'
    }
    'record_size' = [PSCustomObject]@{
        'length'           = 3
        'type'             = 'numeric'
        'required_content' = '094'
    }
    'blocking_factor' = [PSCustomObject]@{
        'length'           = 2
        'type'             = 'numeric'
        'required_content' = '10'
    }
    'format_code' = [PSCustomObject]@{
        'length'           = 1
        'type'             = 'numeric'
        'required_content' = '1'
    }
    'immediate_destination_name' = [PSCustomObject]@{
        'length' = 23
        'type'   = 'alphanumeric'
    }
    'immediate_origin_name' = [PSCustomObject]@{
        'length' = 23
        'type'   = 'alphanumeric'
    }
    'reference_code' = [PSCustomObject]@{
        'length' = 23
        'type'   = 'alphanumeric'
    }
    
    # 5 - BATCH HEADER RECORD FIELDS
    'service_class_code'= [PSCustomObject]@{
        'length' = 3
        'type'   = 'numeric'
    }
    'company_name'= [PSCustomObject]@{
        'length' = 16
        'type'   = 'alphanumeric'
    }
    'company_discretionary_data_5'= [PSCustomObject]@{
        'length' = 20
        'type'   = 'alphanumeric'
    }
    'company_identification'= [PSCustomObject]@{
        'length' = 10
        'type'   = 'alphanumeric'
    }
    'standard_entry_class_code'= [PSCustomObject]@{
        'length' = 3
        'type'   = 'alphanumeric'
    }
    'company_entry_description'= [PSCustomObject]@{
        'length' = 10
        'type'   = 'alphanumeric'
    }
    'company_descriptive_date'= [PSCustomObject]@{
        'length' = 6
        'type'   = 'alphanumeric'
    }
    'effective_entry_date'= [PSCustomObject]@{
        'length' = 6
        'type'   = 'alphanumeric'
    }
    'settlement_date'= [PSCustomObject]@{
        'length' = 3
        'type'   = 'alphanumeric'
    }
    'originator_status_code'= [PSCustomObject]@{
        'length'           = 1
        'type'             = 'numeric'
        'required_content' = '1'
    }
    'originating_dfi_identification'= [PSCustomObject]@{
        'length' = 8
        'type'   = 'numeric'
    }
    'batch_number'= [PSCustomObject]@{
        'length' = 7
        'type'   = 'numeric'
    }
    
    # 6 - ENTRY DETAIL RECORD FIELDS
    'transaction_code' = [PSCustomObject]@{
        'length' = 2
        'type'   = 'numeric'
    }
    'receiving_dfi_identification' = [PSCustomObject]@{
        'length' = 8
        'type'   = 'numeric'
    }
    'check_digit' = [PSCustomObject]@{
        'length' = 1
        'type'   = 'numeric'
    }
    'dfi_account_number' = [PSCustomObject]@{
        'length' = 17
        'type'   = 'alphanumeric'
    }
    'amount' = [PSCustomObject]@{
        'length' = 10
        'type'   = 'numeric_dollar'
    }
    'individual_identification_number' = [PSCustomObject]@{
        'length' = 15
        'type'   = 'alphanumeric'
    }
    'individual_name' = [PSCustomObject]@{
        'length' = 22
        'type'   = 'alphanumeric'
    }
    'company_discretionary_data_6' = [PSCustomObject]@{
        'length' = 2
        'type'   = 'alphanumeric'
    }
    'addenda_record_indicator' = [PSCustomObject]@{
        'length' = 1
        'type'   = 'numeric'
    }
    'trace_number' = [PSCustomObject]@{
        'length' = 15
        'type'   = 'numeric'
    }
    
    # 8 - BATCH CONTROL RECORD FIELDS
    'entry_addenda_count_8' = [PSCustomObject]@{
        'length' = 6
        'type'   = 'numeric'
    }
    'entry_hash' = [PSCustomObject]@{
        'length' = 10
        'type'   = 'numeric'
    }
    'total_debit_entry' = [PSCustomObject]@{
        'length' = 12
        'type'   = 'numeric_dollar'
    }
    'total_credit_entry' = [PSCustomObject]@{
        'length' = 12
        'type'   = 'numeric_dollar'
    }
    'message_authorization_code' = [PSCustomObject]@{
        'length' = 19
        'type'   = 'alphanumeric'
    }
    'reserved_8' = [PSCustomObject]@{
        'length' = 6
        'type'   = 'blank'
    }
    
    # 9 - FILE CONTROL RECORD FIELDS
    'batch_count' = [PSCustomObject]@{
        'length' = 6
        'type'   = 'numeric'
    }
    'block_count' = [PSCustomObject]@{
        'length' = 6
        'type'   = 'numeric'
    }
    'entry_addenda_count_9' = [PSCustomObject]@{
        'length' = 8
        'type'   = 'numeric'
    }
    'total_debit_entry_in_file' = [PSCustomObject]@{
        'length' = 12
        'type'   = 'numeric_dollar'
    }
    'total_credit_entry_in_file' = [PSCustomObject]@{
        'length' = 12
        'type'   = 'numeric_dollar'
    }
    'reserved_9' = [PSCustomObject]@{
        'length' = 39
        'type'   = 'blank'
    }
}
