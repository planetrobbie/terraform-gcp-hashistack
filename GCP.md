# Google Cloud (GCP) Getting Started Guide

In this guide we assume you start from scratch, you just need a Google account and a billing account enabled for Google Cloud.

## Google Cloud SDK

The fastest way to be efficient with GCP is to use their [SDK](https://cloud.google.com/sdk/install), start by installing it.

    curl https://sdk.cloud.google.com | bash

Restart your shell with

    exec -l $SHELL

If you already have it on your system, update it.

    gcloud components update

## Create a Project to Host your Cluster

    gcloud projects create <PROJECT_NAME> --organization=<ORGANIZATION_ID> --set-as-default

## SDK Configuration

Initialize your SDK and when doing so, when asked, choose the project you created earlier.

    gcloud init

From now on all `gcloud` commands will target this project.

## Enable APIs

Your project is brand new, so you need to enable the required APIs. You can list all of them with

    gcloud services list --available

Enable the following ones

    gcloud services enable compute.googleapis.com
    gcloud services enable iam.googleapis.com
    gcloud services enable cloudkms.googleapis.com
    gcloud services enable dns.googleapis.com
    gcloud services enable cloudresourcemanager.googleapis.com [for account binding]

## Create a Service Account

A Service Account is like a robot account used to automate provisioning on GCP. Terraform will use a Service Account Key to authenticate to GCP.

Create one like this

    gcloud iam service-accounts create <PROJECT_NAME>-tf --display-name "<PROJECT_NAME>-tf Account"

And create and download a corresponding JSON credentials

    gcloud iam service-accounts keys create \
        ~/.config/gcloud/<PROJECT_NAME>-tf.json \
        --iam-account <PROJECT_NAME>-tf@<PROJECT_NAME>.iam.gserviceaccount.com

Protect this file as well as you can, it gives access to your project.

Now grant service account project ownership

    gcloud projects add-iam-policy-binding <PROJECT_NAME> --member \
    'serviceAccount:<PROJECT_NAME>-tf@<PROJECT_NAME>.iam.gserviceaccount.com' \
     --role 'roles/owner'

Note: Make sure your account is linked to a billing account.

This ends the setup of your Google Cloud environment ! Congrats.

You can get back to the [main documentation](README.md).