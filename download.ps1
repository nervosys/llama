# PowerShell script for downloading Llama models.

# Copyright (c) Nervosys, LLC. and affiliates.
# This software may be used and distributed according to the terms of the Llama 2 Community License Agreement.

$PRESIGNED_URL = Read-Host "Enter the URL from email: "

Write-Output.

$MODEL_SIZE = Read-Host "Enter the list of models to download without spaces (7B,13B,70B,7B-chat,13B-chat,70B-chat), or press Enter for all: "

if ( "" -eq $MODEL_SIZE ) {
    $MODEL_SIZE = "7B,13B,70B,7B-chat,13B-chat,70B-chat"
}

# create target directory, where all files should end up
$TARGET_FOLDER = "."
New-Item -Path $TARGET_FOLDER -Type Directory

Write-Output "Downloading LICENSE and Acceptable Usage Policy"
Invoke-WebRequest -Uri ${PRESIGNED_URL}/'*'/"LICENSE" -OutFile ${TARGET_FOLDER}"/LICENSE"
Invoke-WebRequest -Uri ${PRESIGNED_URL}/'*'/"USE_POLICY.md" -OutFile ${TARGET_FOLDER}"/USE_POLICY.md"

Write-Output "Downloading tokenizer"
Invoke-WebRequest -Uri ${PRESIGNED_URL}/'*'/"tokenizer.model" -OutFile ${TARGET_FOLDER}"/tokenizer.model"
Invoke-WebRequest -Uri ${PRESIGNED_URL}/'*'/"tokenizer_checklist.chk" -OutFile ${TARGET_FOLDER}"/tokenizer_checklist.chk"

$CPU_ARCH = $env:PROCESSOR_ARCHITECTURE  # possible values: [ AMD64 | X86 | IA64 | ARM64 | EM64T ]

if ( $CPU_ARCH -eq "ARM64" ) {
    (Set-Location ${TARGET_FOLDER} && md5 tokenizer_checklist.chk)
}
else {
    (Set-Location ${TARGET_FOLDER} && md5sum -c tokenizer_checklist.chk)
}

$MODEL_ARRAY = $MODEL_SIZE.Split(",").Trim()

foreach ( $MODEL in $MODEL_ARRAY ) {

    switch ( $MODEL ) {
        "7B" {
            $SHARD = 0
            $MODEL_PATH = "llama-2-7b"
        }
        "7B-chat" {
            $SHARD = 0
            $MODEL_PATH = "llama-2-7b-chat"
        }
        "13B" {
            $SHARD = 1
            $MODEL_PATH = "llama-2-13b"
        }
        "13B-chat" {
            $SHARD = 1
            $MODEL_PATH = "llama-2-13b-chat"
        }
        "70B" {
            $SHARD = 7
            $MODEL_PATH = "llama-2-70b"
        }
        "70B-chat" {
            $SHARD = 7
            $MODEL_PATH = "llama-2-70b-chat"
        }
    }
    
    Write-Output "Downloading ${MODEL_PATH}"
    New-Item -Path ${TARGET_FOLDER}"/"${MODEL_PATH} -Type Directory

    foreach ( $s in 0..$SHARD ) {
        [String]$pad = '{0:d4}' -f $s  # 0-pad left four decimal places using format (-f) operator
        Invoke-WebRequest -Uri ${PRESIGNED_URL}/'*'/"${MODEL_PATH}/consolidated.${pad}.pth" -OutFile ${TARGET_FOLDER}"/${MODEL_PATH}/consolidated.${pad}.pth"
    }

    Invoke-WebRequest -Uri ${PRESIGNED_URL}/'*'/${MODEL_PATH}"/params.json" -OutFile ${TARGET_FOLDER}"/"${MODEL_PATH}"/params.json"
    Invoke-WebRequest -Uri ${PRESIGNED_URL}/'*'/${MODEL_PATH}"/checklist.chk" -OutFile ${TARGET_FOLDER}"/"${MODEL_PATH}"/checklist.chk"

    Write-Output "Checking checksums"
    if ( "arm64" -eq $CPU_ARCH ) {
      (Set-Location ${TARGET_FOLDER}"/${MODEL_PATH}" && md5 checklist.chk)
    }
    else {
      (Set-Location ${TARGET_FOLDER}"/${MODEL_PATH}" && md5sum -c checklist.chk)
    }

}
