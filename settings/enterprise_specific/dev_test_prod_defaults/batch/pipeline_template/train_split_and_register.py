#import json
import logging
import os
#import pickle
import pandas as pd
#import joblib
#import azureml.automl.core
from azureml.automl.core.shared import logging_utilities, log_server
from azureml.telemetry import INSTRUMENTATION_KEY
import argparse
from azureml.core import Run
from azureml.data.dataset_factory import FileDatasetFactory
#import datetime
#import uuid
from your_code.your_train_code import Trainer

try: # not needed, but since AutoML scoring script copied, we'll keep this logging.
    log_server.enable_telemetry(INSTRUMENTATION_KEY)
    log_server.set_verbosity('INFO')
    logger = logging.getLogger('azureml.automl.core.scoring_script')
except:
    pass

def split():
    global gold_to_split,train,validate,test,datastore,train_ds,validate_ds,test_ds,esml_output_lake_template_train,esml_output_lake_template_validate,esml_output_lake_template_test

    parser = argparse.ArgumentParser("Split the GOLD to TRAIN, TEST, VALIDATE and register as AML datasets")
    parser.add_argument('--target_column_name', dest="target_column_name", type=str, required=True)
    parser.add_argument('--par_esml_training_date', dest="par_esml_training_date", required=True)
    parser.add_argument('--par_esml_split_percentage', dest="par_esml_split_percentage",type=float, required=True)
    parser.add_argument('--par_esml_inference_mode', dest='par_esml_inference_mode', type=int, required=True)
    parser.add_argument('--esml_output_lake_template_train', dest='esml_output_lake_template_train',help='Template path with place holders to write TRAIN dataset',required=True)
    parser.add_argument('--esml_output_lake_template_validate', dest='esml_output_lake_template_validate',help='Template path with place holders to write VALIDATE dataset',required=True)
    parser.add_argument('--esml_output_lake_template_test', dest='esml_output_lake_template_test',help='Template path with place holders to write TEST dataset',required=True)

    #Optional
    parser.add_argument('--par_esml_env', type=str, help='ESML environment: dev,test,prod', required=False)
        
    args = parser.parse_args()

    try:
        split_percentage = args.par_esml_split_percentage # Split percentage for TRAIN, default 0.6
        esml_inference_mode = bool(args.par_esml_inference_mode) # Verify, should be False
        esml_output_lake_template_train = args.esml_output_lake_template_train
        esml_output_lake_template_validate = args.esml_output_lake_template_validate
        esml_output_lake_template_test = args.esml_output_lake_template_test

        run = Run.get_context()
        ws = run.experiment.workspace
        datastore = ws.get_default_datastore()

        gold_to_split = next(iter(run.input_datasets.items()))[1] # Get DATASET
        logger.info("Azure Dataset GOLD to SPLIT, loaded successfully. {}".format(gold_to_split.name))
        print(" Azure ML Dataset, golgold_to_splitd_to_score, is = {}".format(gold_to_split))
        
        
        # 1) Register TRAIN df as dataset
        it = iter(run.output_datasets)
        train_ds_name =  next(it)
        train_ds = run.output_datasets[train_ds_name]

        # 2) Register TEST set df as dataset
        validate_ds_name =  next(it)
        validate_ds = run.output_datasets[validate_ds_name]

        # 3) Register VALIDATE df as dataset
        test_ds_name =  next(it)
        test_ds = run.output_datasets[test_ds_name]

        ################### 1) EDIT: SPLIT the GOLD data, as you wish #########################

        train,validate,test = Trainer.split_gold(gold_to_split, train_percentage=split_percentage, label=args.target_column_name)

        ################### 1) end EDIT: SPLIT the GOLD data, as you wish = Done #########################

        logger.info("SPLIT_GOLD.init() success: Splitted GOLD, and registered Datasets, now lets REGISTER them in the run() method")

    except Exception as e:
        logging_utilities.log_traceback(e, logger)
        raise

def register(train,validate,test):
    try:
        
        run = Run.get_context()
        print("Piepline run.id {}".format(run.id))
        run_id = run.parent.id #run.id
        print("Piepline run.parent.id {}".format(run_id))

        train_df = train.reset_index(drop=True) # Make sure index is gone
        validate_df = validate.reset_index(drop=True) # Make sure index is gone
        test_df = test.reset_index(drop=True) # Make sure index is gone
        
        train_file = 'gold_train.parquet'
        validate_file = 'gold_validate.parquet'
        test_file = 'gold_test.parquet'

        logger.info("Registering TRAIN dataframe as Azure ML Dataset")
        if not (train_ds is None):
            os.makedirs(train_ds, exist_ok=True)
            print("%s created" % train_ds)
            
            path = train_ds + "/"+ train_file

            logger.info("Saving result as PARQUET at: {}".format(path))
            print ("train_ds.path is: {}".format(path))
            print("Local Path from run.output_datasets[train_ds]:{}/{}'".format(train_ds,train_file))

            written_df = train_df.to_parquet(path,engine='pyarrow', index=False,use_deprecated_int96_timestamps=True,allow_truncated_timestamps=False)
            
            #new_path = esml_output_lake_template_train.format(id_folder=run_id)
            #print ("esml_output_lake_template path: {}".format(new_path))
            #FileDatasetFactory.upload_directory(src_dir=train_ds, target=(datastore, new_path), pattern=None, overwrite=True, show_progress=False)

            logger.info("Registering VALIDATE dataframe as Azure ML Dataset")
        if not (validate_ds is None):
            os.makedirs(validate_ds, exist_ok=True)
            print("%s created" % validate_ds)
            path = validate_ds + "/" + validate_file

            print ("validate_ds.path is: {}".format(path))
            print("Local Path from run.output_datasets[validate_ds]:{}/{}'".format(validate_ds,validate_file))

            write_df2 = validate_df.to_parquet(path, engine='pyarrow', index=False,use_deprecated_int96_timestamps=True,allow_truncated_timestamps=False)
            logger.info("Saving result as PARQUET at: {}".format(path))

            #new_path = esml_output_lake_template_validate.format(id_folder=run_id)
            #print ("esml_output_lake_template path: {}".format(new_path))
            #FileDatasetFactory.upload_directory(src_dir=train_ds, target=(datastore, new_path), pattern=None, overwrite=True, show_progress=False)

            logger.info("Registering TEST dataframe as Azure ML Dataset")
        if not (test_ds is None):
            os.makedirs(test_ds, exist_ok=True)
            print("%s created" % test_ds)
            path = test_ds + "/" + test_file

            print ("test_ds.path is: {}".format(path))
            print("Local Path from run.output_datasets[validate_ds]:{}/{}'".format(test_ds,test_file))

            write_df3 = test_df.to_parquet(path, engine='pyarrow', index=False,use_deprecated_int96_timestamps=True,allow_truncated_timestamps=False)
            logger.info("Saving result as PARQUET at: {}".format(path))

            #new_path = esml_output_lake_template_test.format(id_folder=run_id)
            #print ("esml_output_lake_template path: {}".format(new_path))
            #FileDatasetFactory.upload_directory(src_dir=train_ds, target=(datastore, new_path), pattern=None, overwrite=True, show_progress=False)

    except Exception as e:
        logging_utilities.log_traceback(e, logger)
        raise

if __name__ == "__main__":
    split()
    register(train,validate,test)