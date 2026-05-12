ALTER TABLE production_log
ADD CONSTRAINT fk_product
FOREIGN KEY (product_id)
REFERENCES product_catalog(product_id);

ALTER TABLE production_log
ADD CONSTRAINT fk_operator
FOREIGN KEY (operator_id)
REFERENCES operators(operator_id);

ALTER TABLE quality_inspection
ADD CONSTRAINT fk_production
FOREIGN KEY (production_id)
REFERENCES production_log(production_id);