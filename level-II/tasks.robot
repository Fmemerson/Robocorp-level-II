*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium
Library             RPA.Excel.Files
Library             RPA.Tables
Library             RPA.HTTP
Library             RPA.PDF
Library             RPA.Archive
Library             OperatingSystem


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Download CSV orders file
    Loop the orders    ${orders}


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Download CSV orders file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True    verify=False
    ${orders}=    Read table from CSV    orders.csv
    RETURN    ${orders}

Loop the orders
    [Arguments]    ${orders}

    FOR    ${order}    IN    @{orders}
        Close the annoying modal
        Select From List By Value    id:head    ${order}[Head]
        FOR    ${btn}    IN    @{orders}
            Select Radio Button    body    ${order}[Body]
        END
        Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${order}[Legs]
        Input Text    address    ${order}[Address]
        Wait Until Keyword Succeeds    30x    5s    Preview
        Wait Until Keyword Succeeds    30x    5s    Order
        Store the order receipt as a PDF file    ${order}[Order number]
        Take a screenshot of the robot    ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file
        ...    ${OUTPUT_DIR}${/}${order}[Order number].png
        ...    ${OUTPUT_DIR}${/}${order}[Order number].pdf
        Delete screenshots    ${OUTPUT_DIR}${/}${order}[Order number].png
        Wait Until Keyword Succeeds    30x    5s    Order Another
    END
    Archive PDFs

Close the annoying modal
    Wait Until Element Is Visible    xpath://html/body/div/div/div[2]/div/div/div/div/div/button[1]
    Click Button    OK

Preview
    Click Button    id:preview
    Wait Until Element Is Visible    id:robot-preview-image

Order
    Click Button    id:order
    Wait Until Element Is Visible    id:receipt

Order Another
    Wait Until Element Is Visible    id:receipt
    Click Button    id:order-another

Store the order receipt as a PDF file
    [Arguments]    ${Order Number}
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${Order Number} ${receipt_html}    ${OUTPUT_DIR}${/}${Order Number}.pdf

Take a screenshot of the robot
    [Arguments]    ${Order Number}
    Wait Until Element Is Visible    id:robot-preview-image
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}${Order Number}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open pdf    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}
    Close Pdf    ${pdf}

Delete screenshots
    [Arguments]    ${directory}
    Remove File    ${directory}

Archive PDFs
    Archive Folder With Zip    ${OUTPUT_DIR}    receipts.zip    include=*.pdf
