#!/bin/sh

name="${1}"

if [ -z "${name}" ]; then
  echo 'usage: update_fruits "fruits_name'
  echo 'update_fruits apple'
  exit ${LINENO}
fi

table_name="Fruits"

# validation check
get_item=$(aws dynamodb get-item \
  --table-name ${table_name} \
  --key "{\"name\":{\"S\": \"${name}\"}}" | \
  jq -r '.Item | "name: " + .name.S
  + "\namount: " + .amount.N
  + "\nitem_count: " + .item_count.N
  + "\nproduction_area: " + .production_area.S
  + "\nis_sale: " + (.is_sale.BOOL | tostring)')

if [ -z "${get_item}" ]; then
  echo "${name} is not exist."
  exit ${LINENO}
fi

# show current value
echo "${get_item}"

action_value="SET"
update_expression="${action_value}"
new_value=""

echo ''
echo "Input update values. (If you don't update it, press the return key.)"

# set amount
read -p "amount: " input_amount
if [ -n "${input_amount}" ]; then
  update_expression="${update_expression} amount = :amount, "
  new_value="${new_value}\":amount\": {\"N\": \"${input_amount}\"}, "
fi

# set item_count
read -p "item_count: " input_item_count
if [ -n "${input_item_count}" ]; then
  update_expression="${update_expression} item_count = :item_count, "
  new_value="${new_value}\":item_count\": {\"N\": \"${input_item_count}\"}, "
fi

# set production_area
read -p "stranded_amount: " input_stranded_amount
if [ -n "${input_stranded_amount}" ]; then
  update_expression="${update_expression} stranded_amount = :stranded_amount, "
  new_value="${new_value}\":stranded_amount\": {\"S\": \"${input_stranded_amount}\"}, "
fi

# set is_sale
read -p "is_sale: " input_is_sale
if [ -n "${input_is_sale}" ]; then
  update_expression="${update_expression} is_sale = :is_sale, "
  new_value="${new_value}\":is_sale\": {\"S\": \"${input_is_sale}\"}, "
fi

# remove ", "
update_expression=$(echo ${update_expression%, })
# add "{}", remove ", "
new_value="{$(echo ${new_value%, })}"

if [ "${update_expression}" == "${action_value}" ]; then
  echo 'Exit without updating anything.'
  exit ${LINENO}
fi

echo "new value: ${new_value}"
read -n1 -p "Are you sure you want to update these? [y/N]: " input

if [[ ${input} = [yY] ]]; then
  echo '\n'
else
  echo '\nUpdate canceled.'
  exit ${LINENO}
fi

aws dynamodb update-item \
  --table-name ${table_name} \
  --key "{\"name\": {\"S\": \"${name}\"}}" \
  --update-expression "${update_expression}" \
  --expression-attribute-values "${new_value}" \
  --return-values ALL_NEW

exit 0

