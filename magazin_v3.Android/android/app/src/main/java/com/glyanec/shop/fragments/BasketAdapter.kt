package com.glyanec.shop.fragments

import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.ImageButton
import android.widget.ImageView
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.bumptech.glide.Glide
import com.glyanec.shop.R
import com.glyanec.shop.data.ItemBasketModel

class BasketAdapter(
    private val onQuantityChanged: (ItemBasketModel, Int) -> Unit,
    private val onItemDeleted: (ItemBasketModel) -> Unit
) : RecyclerView.Adapter<BasketAdapter.ViewHolder>() {
    
    private var items: List<ItemBasketModel> = emptyList()
    
    fun submitList(newItems: List<ItemBasketModel>) {
        items = newItems
        notifyDataSetChanged()
    }
    
    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_basket, parent, false)
        return ViewHolder(view)
    }
    
    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        holder.bind(items[position])
    }
    
    override fun getItemCount(): Int = items.size
    
    inner class ViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val itemImage: ImageView = itemView.findViewById(R.id.itemImage)
        private val itemTitle: TextView = itemView.findViewById(R.id.itemTitle)
        private val itemPrice: TextView = itemView.findViewById(R.id.itemPrice)
        private val quantityTextView: TextView = itemView.findViewById(R.id.quantityTextView)
        private val decreaseButton: Button = itemView.findViewById(R.id.decreaseButton)
        private val increaseButton: Button = itemView.findViewById(R.id.increaseButton)
        private val deleteButton: ImageButton = itemView.findViewById(R.id.deleteButton)
        
        fun bind(item: ItemBasketModel) {
            itemTitle.text = item.title
            itemPrice.text = "${item.price} грн"
            quantityTextView.text = item.qty.toString()
            
            // Завантажуємо зображення через Glide
            Log.d("BasketAdapter", "Loading image: ${item.image}")
            if (item.image.isNotEmpty()) {
                Glide.with(itemView.context)
                    .load(item.image)
                    .placeholder(R.drawable.ic_launcher_foreground)
                    .error(R.drawable.ic_launcher_foreground)
                    .into(itemImage)
            } else {
                itemImage.setImageResource(R.drawable.ic_launcher_foreground)
            }
            
            decreaseButton.setOnClickListener {
                val newQty = (item.qty - 1).coerceAtLeast(1)
                onQuantityChanged(item, newQty)
            }
            
            increaseButton.setOnClickListener {
                val newQty = item.qty + 1
                onQuantityChanged(item, newQty)
            }
            
            deleteButton.setOnClickListener {
                onItemDeleted(item)
            }
        }
    }
}

