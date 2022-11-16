*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             OperatingSystem
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${RobotSpareBinInc}=    Get Secret    RobotSpareBinInc
    ${fileURL}=    User Dialog for File URL
    Open the robot order website    ${RobotSpareBinInc}[robotOrderURL]
    ${orders}=    Get orders    ${fileURL}
    # https://robotsparebinindustries.com/orders.csv
    FOR    ${order}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${order}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${order}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${pdf}    ${screenshot}
        Go to order another robot
    END
    Create a ZIP file of the receipts


*** Keywords ***
Open the robot order website
    [Arguments]    ${robotOrderURL}
    Open Available Browser    ${robotOrderURL}    maximized= True
    Wait Until Element Is Visible    css:.btn-dark

User Dialog for File URL
    Add heading    Provide URL of file
    Add text input    promptedValue    label= URL
    ${result}=    Run dialog
    RETURN    ${result.promptedValue}

Get orders
    [Arguments]    ${fileURL}
    Download    ${fileURL}    overwrite= ${True}
    ${table}=    Read table from CSV    orders.csv    header= ${True}
    RETURN    ${table}

Close the annoying modal
    Click Button    css:.btn-dark

Fill the form
    [Arguments]    ${order}
    Select From List By Value    id:head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    #${legid}=    Get Element Attribute    //*[text()= "3. Legs:"]    for
    #Input Text    id:${legid}    ${order}[Legs]
    Input Text    //*[@placeholder="Enter the part number for the legs"]    ${order}[Legs]
    Input Text    id:address    ${order}[Address]

Preview the robot
    Click Button    id:preview

Submit the order
    ${orderRetryCount}=    Set Variable    ${0}
    WHILE    ${orderRetryCount} < ${10}
        Click Button    id:order
        Sleep    2s
        ${orderCondition}=    Does Page Contain Button    id:order-another
        IF    ${orderCondition} == ${True}
            BREAK
        ELSE
            ${orderRetryCount}=    Set Variable    ${orderRetryCount + 1}
        END
    END

Store the receipt as a PDF file
    [Arguments]    ${orderNumber}
    ${receipt_outerHTML}=    Get Element Attribute    id:order-completion    outerHTML
    # ${pdfPath}=    Set Variable    ${OUTPUT_DIR}${/}Receipts${/}Receipt ${orderNumber}.pdf
    ${pdfPath}=    Set Variable    ${OUTPUT_DIR}${/}Receipt ${orderNumber}.pdf
    Html To Pdf    ${receipt_outerHTML}    ${pdfPath}
    RETURN    ${pdfPath}

Take a screenshot of the robot
    [Arguments]    ${orderNumber}
    # ${imagePath}=    Set Variable    ${OUTPUT_DIR}${/}Robot Images${/}Robot ${orderNumber}.png
    ${imagePath}=    Set Variable    ${OUTPUT_DIR}${/}Robot ${orderNumber}.png
    Screenshot    id:robot-preview-image    ${imagePath}
    RETURN    ${imagePath}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${pdf}    ${screenshot}
    ${filesToBeAdded}=    Create List
    ...    ${screenshot}
    Add Files To Pdf    ${filesToBeAdded}    ${pdf}    append= ${True}
    Close All Pdfs

Go to order another robot
    Click Button    id:order-another

Create a ZIP file of the receipts
    Remove File    ${OUTPUT_DIR}${/}ReceiptPDFs.zip

    Archive Folder With Zip
    ...    folder=${OUTPUT_DIR}${/}
    ...    archive_name=${OUTPUT_DIR}${/}ReceiptPDFs.zip
    ...    include=Receipt *.pdf

    ${pngFiles}=    List Files In Directory    ${OUTPUT_DIR}${/}    pattern=Robot *.png
    FOR    ${pngFile}    IN    @{pngFiles}
        Remove File    ${OUTPUT_DIR}${/}${pngFile}
    END

    ${pdfFiles}=    List Files In Directory    ${OUTPUT_DIR}${/}    pattern=Receipt *.pdf
    FOR    ${pdfFile}    IN    @{pdfFiles}
        Remove File    ${OUTPUT_DIR}${/}${pdfFile}
    END
