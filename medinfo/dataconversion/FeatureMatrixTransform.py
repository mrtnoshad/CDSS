#!/usr/bin/python
"""
Module for transforming the values within an existing feature matrix.
"""

import numpy as np
import pandas as pd

from sklearn.preprocessing import Imputer

class FeatureMatrixTransform():
    IMPUTE_STRATEGY_MEAN = 'mean'
    IMPUTE_STRATEGY_MEDIAN = 'median'
    IMPUTE_STRATEGY_MODE = 'most-frequent'

    LOG_BASE_10 = 'log-base-10'
    LOG_BASE_E = 'log-base-e'

    def __init__(self):
        self._matrix = None

    def set_input_matrix(self, matrix):
        if type(matrix) != pd.core.frame.DataFrame:
            raise ValueError('Input matrix must be pandas DataFrame.')

        self._matrix = pd.DataFrame.copy(matrix)

    def fetch_matrix(self):
        return self._matrix

    def impute(self, feature=None, strategy=None):
        if self._matrix is None:
            raise ValueError('Must call set_input_matrix() before impute().')

        # If user does not specify which feature to impute, impute values
        # for all columns in the matrix.
        if feature is None:
            feature = 'all-features'

        # If an imputation strategy is not specified, default to mean.
        if strategy is None:
            strategy = FeatureMatrixTransform.IMPUTE_STRATEGY_MEAN

        self._impute_single_feature(feature=feature, strategy=strategy)

    def _impute_single_feature(self, feature, strategy):
        if strategy == FeatureMatrixTransform.IMPUTE_STRATEGY_MEAN:
            if feature == 'all-features':
                for column in self._matrix:
                    self._matrix[column] =  self._matrix[column].fillna(self._matrix[column].mean(0))
            self._matrix[feature] =  self._matrix[feature].fillna(self._matrix[feature].mean(0))
        elif strategy == FeatureMatrixTransform.IMPUTE_STRATEGY_MODE:
            if feature == 'all-features':
                for column in self._matrix:
                    self._matrix[column] = self._matrix[column].fillna(self._matrix[column].mode().iloc[0])
            else:
                self._matrix[feature] = self._matrix[feature].fillna(self._matrix[feature].mode().iloc[0])

    def remove_feature(self, feature):
        del self._matrix[feature]

    def add_logarithm_feature(self, base_feature, logarithm=None):
        if logarithm is None:
            logarithm = FeatureMatrixTransform.LOG_BASE_E

        col_index = self._matrix.columns.get_loc(base_feature)

        if logarithm == FeatureMatrixTransform.LOG_BASE_E:
            log_feature = 'ln(' + base_feature + ')'
            new_col = self._matrix[base_feature].apply(np.log)
            self._matrix.insert(col_index + 1, log_feature, new_col)
        elif logarithm == FeatureMatrixTransform.LOG_BASE_10:
            log_feature = 'log10(' + base_feature + ')'
            new_col = self._matrix[base_feature].apply(np.log10)
            self._matrix.insert(col_index, log_feature, new_col)

    def _boolean_indicator(self, value):
        return pd.notnull(value)

    def _numeric_indicator(self, value):
        return 1 if pd.notnull(value) else 0

    def add_indicator_feature(self, base_feature, boolean_indicator=None):
        # boolean: determines whether to add True/False labels or 1/0
        if boolean_indicator is None or boolean_indicator is False:
            indicator = self._numeric_indicator
        else:
            indicator = self._boolean_indicator

        col_index = self._matrix.columns.get_loc(base_feature)
        indicator_feature = 'I(' + base_feature + ')'
        new_col = self._matrix[base_feature].apply(indicator)
        self._matrix.insert(col_index + 1, indicator_feature, new_col)